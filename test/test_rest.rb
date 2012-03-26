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

  def while_logged_in
    with_valid_credentials do
      @conn = new_rest(@@good_creds)
      @login_response = @conn.login(true)
      yield
    end
  end

  def test_login_success
    while_logged_in do
      assert_equal(@login_response.code,200)
    end
  end

  def test_login_failure
    with_invalid_credentials do
      assert_raises(Rest::LoginError){ new_rest(@@bad_creds).login }
    end
  end

  def test_checks_authentication
    with_valid_credentials do
      conn = new_rest(@@good_creds)
      refute conn.authenticated?
      conn.login
      assert conn.authenticated?
    end
  end

  def test_exception_without_login
    with_invalid_credentials do
      assert_raises(Rest::NotAuthenticated){ new_rest(@@bad_creds).defects }
    end
  end

  def test_exception_on_bad_path
    while_logged_in do
      assert_raises(Rest::UnrecognizedResponse){ @conn.auth_get '/blah' }
    end
  end

end
