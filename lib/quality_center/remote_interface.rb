require 'httparty'

module QualityCenter

  class RemoteInterface
    include HTTParty
    base_uri 'qualitycenter.ic.ncs.com:8080'
    AUTHURI  = {
      get:  '/qcbin/authentication-point/login.jsp',
      post: '/qcbin/authentication-point/j_spring_security_check'
    }
    PREFIX  = '/qcbin/rest'
    DEFECTS = '/domains/TEST/projects/AssessmentQualityGroup/defects'
    def initialize(u,p)
      @login = {:j_username => u, :j_password => p}
    end

    def login
      response = self.class.get AUTHURI[:get]
      response = self.class.post(
        AUTHURI[:post],
        body:    @login,
        headers: {'Cookie' => response.headers['Set-Cookie']}
      )
      raise "Login Error" if response.request.uri.to_s =~ /error/

      @cookie = response.request.options[:headers]['Cookie']
      response
    end

    def auth_get(url,prefix = PREFIX)
      login unless authenticated?
      self.class.get( prefix+url, headers: {'Cookie' => @cookie} )
    end

    def authenticated?
      return false unless @cookie
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

    def recent_events
      "http://qualitycenter.ic.ncs.com:8080/qcbin/rest/domains/{domain}/projects/{project}/event-logs"
    end

    def paging
      'page-size=10&start-index=30'
    end

  end

end
