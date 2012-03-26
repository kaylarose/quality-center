require_relative 'test_helper'
require 'webmock'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
end

module RestHelper
  include QualityCenter::RemoteInterface

  @@good_creds = {user:'valid_user',   password:'valid_password'}
  @@bad_creds  = {user:'invalid_user', password:'invalid_password'}
  @@match_opts = {:match_requests_on => [:uri,:body]}

  def new_rest(creds)
    Rest.new(creds.merge(logger: Logger.new('/dev/null')))
  end

  def with_valid_credentials
    VCR.use_cassette('successful_login',@@match_opts){ yield }
  end

  def with_invalid_credentials
    VCR.use_cassette('failed_login',@@match_opts){ yield }
  end

  def while_logged_in
    with_valid_credentials do
      @conn = new_rest(@@good_creds)
      @login_response = @conn.login(true)
      yield
    end
  end

end
