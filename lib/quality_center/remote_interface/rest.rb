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

      def auth_get(url,prefix = PREFIX)
        res = self.class.get( prefix+url, headers: {'Cookie' => @cookie} )
        assert_valid(res)
        res.body
      end

      def users
        scoped_get('/users')
      end

      def defects
        scoped_get('/defects')
      end

      def defect_fields
        scoped_get('/customization/entities/defect/fields')
      end

      # get a path scoped to a predefined domain and project
      def scoped_get(path)
        auth_get(SCOPE + path)
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
      raise LoginError                         if res.response.code == '401'
      raise UnrecognizedResponse,response.code if res.response.code != '200'
    end

    end
  end
end
