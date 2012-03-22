require 'httparty'
require_relative 'exceptions'
require_relative '../constants'

module QualityCenter
  module RemoteInterface
    class Rest

      include HTTParty
      base_uri 'qualitycenter.ic.ncs.com:8080'
      def initialize(u,p)
        @login = {:j_username => u, :j_password => p}
        @cookie = ''
      end

      def login
        response = self.class.get AUTHURI[:get]
        response = self.class.post(
          AUTHURI[:post],
          body:    @login,
          headers: {'Cookie' => response.headers['Set-Cookie']}
        )
        raise LoginError, "Bad credentials" if response.request.uri.to_s =~ /error/

        @cookie = response.request.options[:headers]['Cookie']
        response
      end

      def auth_get(url,opts={})
        opts.reverse_merge!(prefix:PREFIX, raw:false)
        puts opts[:prefix]+url
        res = self.class.get( opts[:prefix]+url, headers: {'Cookie' => @cookie} )
        assert_valid(res)
        opts[:raw] ? res.response.body : res.parsed_response
      end

      def users(opts={})
        scoped_get('/customization/users',opts)
      end

      def defects(opts={})
        scoped_get('/defects',opts)
      end

      def defect_fields(opts={})
        scoped_get('/customization/entities/defect/fields',opts)
      end

      # get a path scoped to a predefined domain and project
      def scoped_get(path,opts={})
        auth_get(SCOPE+path,opts)
      end

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

    end
  end
end
