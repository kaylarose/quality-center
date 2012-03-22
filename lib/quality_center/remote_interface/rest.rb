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
        puts @cookie.inspect
        response
      end

      def auth_get(url,prefix = PREFIX)
        res = self.class.get( prefix+url, headers: {'Cookie' => @cookie} )
        raise LoginError if res.response.code == '401'
        res
      end

      def users(path)
        scoped_get('/users')
      end

      def defects(path)
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

      # WIP
      def root
        ret = {}
        xml = auth_get('')
        parsed = Nokogiri::XML.parse(xml)
        parsed.css('ns2|workspace').each do |workspace|
          ret[workspace.css('title').first.text] = 
            Hash[
              workspace.css('ns2|collection').map{|x| [x.text,x.attributes['href'].value] }
            ]
        end
        ret
      end
    end

  end
end
