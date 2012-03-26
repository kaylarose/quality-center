require_relative 'rest_helper'

class TestRest < Test::Unit::TestCase
  include RestHelper

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
