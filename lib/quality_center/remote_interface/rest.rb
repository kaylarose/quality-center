require 'httparty'
require 'logger'
require_relative 'exceptions'
require_relative '../constants'

module QualityCenter
  module RemoteInterface

    # Wraps the QC Restful API.
    # qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/webframe.html
    # 
    # user     - Login username
    # password - Login password
    # logger   - A Logger to write HTTP calls to (optional)
    #
    # Example
    #
    #   connection = Rest.new(user:'user', password:'secret')
    #   connection.login
    #   defects = connection.defects
    class Rest

      include HTTParty

      base_uri BASE_URI
      
      def initialize(opts={})
        raise ArgumentError 'No User/Pass' unless opts[:user] && opts[:password]

        @logger = opts[:logger] || Logger.new(STDOUT)
        @login  = { :j_username => opts[:user], 
                    :j_password => opts[:password] }
        @cookie = ''
      end

      # Log in to the QC server using the credentials set at initialization.
      # This uses the 'user-facing' login page, due to problems with the method at
      # qualitycenter:8080/qcbin/Help/doc_library/api_refs/REST/Content/General/Authenticate.html
      #
      # Returns the server response if the login is successful.
      # Raises LoginError if the credentials were not accepted.
      def login
        response = self.class.get AUTH_URI[:get]
        response = self.class.post(
          AUTHURI[:post],
          body:    @login,
          headers: {'Cookie' => response.headers['Set-Cookie']}
        )
        raise LoginError, "Bad credentials" if response.request.uri.to_s =~ /error/

        @cookie = response.request.options[:headers]['Cookie']
        response
      end

      # Retrieve the contents of a path, respecting authentication cookies.
      # 
      # path - The url fragment to fetch.  Will be concatenated with PREFIX
      # opts - :prefix - The string to prepend to the path
      #                  default: PREFIX
      #        :raw    - Whether to return unprocessed raw XML, or a parsed hash
      #                  default: false
      # Examples
      #
      #   auth_get '/entities'
      #   # => (array of Entity hashes)
      #
      #   auth_get '/somethings', raw:true
      #   # => "<xml><somethings></somethings></xml>"
      #
      # Returns a hash or string representing the requested resource.
      def auth_get(path,opts={})
        opts.reverse_merge!(prefix:PREFIX, raw:false)
        url = opts[:prefix] + path
        assert_valid(res = stateful_get(url,opts) )

        # return raw xml if caller wants it,    otherwise a hash.
        return opts[:raw] ? res.response.body : res.parsed_response
      end

      # The list of QC users
      def users(opts={})
        scoped_get('/customization/users',opts)
      end

      def defects(opts={})
        scoped_get('/defects',opts)
      end

      # The field definitions for QC defects.
      def defect_fields(opts={})
        scoped_get('/customization/entities/defect/fields',opts)
      end

      # Is the current session authenticated?
      #
      # Returns a boolean indicating whether QC likes us.
      def authenticated?
        return false if @cookie.empty?
        return case self.class.get('/qcbin/rest/is-authenticated',
                                   headers: {'Cookie' => @cookie}).response.code
          when '200' then true
          else false
        end
      end

      private

      # Check that a HTTP response is OK.
      def assert_valid(res)
        raise LoginError, res.response.code          if res.response.code == '401'
        raise UnrecognizedResponse,res.response.code if res.response.code != '200'
      end

      # Get somethig using the cookie
      def stateful_get(url,opts)
        raise NotAuthenticated if @cookie.empty?

        # Only pass in the query option if a query was given
        get_opts         = {headers: {'Cookie' => @cookie}}
        get_opts[:query] = opts[:query] if opts[:query]

        self.class.get(url, get_opts).log(@logger)
      end

      # Get a path scoped to a predefined domain and project
      def scoped_get(path,opts={})
        auth_get(SCOPE+path,opts)
      end

    end
  end
end

# Patch the Response class to make logging cleaner.
module HTTParty
  class Response
    def log(logger)
      logger.debug "#{response.code} #{response.message} #{request.uri}"
      self
    end
  end
end
