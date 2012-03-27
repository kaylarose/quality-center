require_relative 'rest_helper'
require_relative 'query_helper'

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

  # Ensure a single-item result is processed correctly.
  # Currently broken due to HTTParty parsing
  def test_single_item_result
    while_logged_in do
      with_queries do
        assert_nothing_raised{ @conn.tasks(query:@single_page_query) }
      end
    end
  end

  # Ensure an empty result is processed correctly
  def test_empty_result
    while_logged_in do
      empty_query = Query.new.filter(id:'>50000')
      assert_nothing_raised{ @conn.tasks(query:empty_query) }
    end
  end

  def test_dynamic_finders
    while_logged_in do
      with_queries do
        assert_block{ ! @conn.tasks(    query:@small_query)[:entities].empty? }
        assert_block{ ! @conn.defects(  query:@small_query)[:entities].empty? }
      end
    end
  end

  # Make sure setting nice_keys=true works
  def test_friendly_fields_true
    while_logged_in do
      with_queries do
        assert_block do
          entities = @conn.tasks(query:@small_query,nice_keys:true)[:entities]
          entities.first.keys.include? "Created By"
        end
      end
    end
  end

  # Make sure setting nice_keys=false works
  def test_friendly_fields_false
    while_logged_in do
      with_queries do
        assert_block do
          entities = @conn.tasks(query:@small_query,nice_keys:false)[:entities]
          entities.first.keys.include? "creation-time"
        end
      end
    end
  end

  def test_users
    while_logged_in do
      assert_block do
        @conn.users["Users"]["User"].first.keys.include? "FullName"
      end
    end
  end


end
