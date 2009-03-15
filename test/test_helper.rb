RAILS_ROOT = File.dirname(__FILE__) + '/..' unless defined?(RAILS_ROOT)

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'notifier'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

# flatten settings hash and write to fixture file
Rake::Task['onebody:build_settings_fixture_file'].invoke

require File.dirname(__FILE__) + '/forgeries'
require File.dirname(__FILE__) + '/test_extensions'

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  def sign_in_as(person, password='secret')
    sign_in_and_assert_name(person.email, person.name, password)
  end

  def sign_in_and_assert_name(email, name, password='secret')
    post_sign_in_form(email, password)
    assert !flash.empty?
    assert_response :redirect
    follow_redirect!
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(name)
  end
  
  def post_sign_in_form(email, password='secret')
    Setting.set_global('Features', 'SSL', true)
    post '/session', :email => email, :password => password
  end
  
  def view_profile(person)
    get "/people/#{person.id}"
    assert_response :success
    assert_template 'people/show'
    assert_select 'h1', Regexp.new(person.name)
  end
  
  def site!(site)
    host! site
    get '/'
  end
  
  def assert_deliveries(count)
    assert_equal count, ActionMailer::Base.deliveries.length
  end
  
  def assert_emails_delivered(email, people)
    people.each do |person|
      matches = ActionMailer::Base.deliveries.select do |delivered|
        delivered.subject == email.subject and \
        delivered.body.index(email.body) and \
        delivered.to == [person.email]
      end
      assert_equal 1, matches.length
    end
  end

  fixtures :all
end
