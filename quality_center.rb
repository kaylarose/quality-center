require 'httparty'
require 'nokogiri'

class QualityCenter
  include HTTParty
  base_uri 'qualitycenter.ic.ncs.com:8080'
  AuthUri  = {
    get:  '/qcbin/authentication-point/login.jsp',
    post: '/qcbin/authentication-point/j_spring_security_check'
  }
  Prefix = '/qcbin/rest'


  def initialize(u,p)
    @login = {:j_username => u, :j_password => p}
  end

  def login
    response = self.class.get AuthUri[:get]
    response = self.class.post(
      AuthUri[:post],
      body:    @login,
      headers: {'Cookie' => response.headers['Set-Cookie']}
    )
    raise "Login Error" if response.request.uri.to_s =~ /error/

    @cookie = response.request.options[:headers]['Cookie']
    response
  end

  def auth_get(url,prefix = Prefix)
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
    workspaces = {}
    xml = auth_get('')
    parsed = Nokogiri::XML.parse(xml)
    parsed.xpath('//ns2:workspace').each do |workspace|
    end
  end


end

