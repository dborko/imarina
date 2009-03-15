require "#{File.dirname(__FILE__)}/../test_helper"

class SignInTest < ActionController::IntegrationTest
  fixtures :people

  should "allow sign in" do
    Setting.set(nil, 'Features', 'SSL', true)
    get '/people'
    assert_redirected_to new_session_path(:from => '/people')
    follow_redirect!
    post '/session', :email => 'bad-email', :password => 'bla'
    assert_response :success
    assert_select 'div#notice', /email address/
    post '/session', :email => people(:peter).email, :password => 'wrong-password'
    assert_response :success
    assert_select 'div#notice', /password/
    post '/session', :email => people(:peter).email, :password => 'secret'
    assert_redirected_to person_path(people(:peter))
  end
  
  should "allow family members to share an email address" do
    Setting.set(nil, 'Features', 'SSL', true)
    # tim
    post '/session', :email => people(:tim).email, :password => 'secret'
    assert_redirected_to person_path(people(:tim))
    follow_redirect!
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(people(:tim).name)
    # jennie
    post '/session', :email => people(:jennie).email, :password => 'password'
    assert_redirected_to person_path(people(:jennie))
    follow_redirect!
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(people(:jennie).name)
  end
  
  should "not allow users to access most actions with feed code" do
    get "/people?code=#{people(:tim).feed_code}"
    assert_response :redirect
    get "/groups?code=#{people(:tim).feed_code}"
    assert_response :redirect
    get "/feed.xml?code=#{people(:tim).feed_code}"
    assert_response :success
    get "/groups/#{groups(:morgan).id}/memberships/#{people(:jeremy).id}?code=#{people(:jeremy).feed_code}&email=off"
    assert_redirected_to people_path
  end
  
end
