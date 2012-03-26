require_relative 'test_helper'

class TestRest < Test::Unit::TestCase
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

  def test_login_success
    with_valid_credentials do
      response = new_rest(@@good_creds).login(true)
      assert_equal(response.code,200)
    end
  end

  def test_login_failure
    with_invalid_credentials do
      assert_raises(Rest::LoginError){ new_rest(@@bad_creds).login }
    end
  end

end
