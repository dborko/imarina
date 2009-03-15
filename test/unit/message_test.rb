require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :messages
  
  include MessagesHelper
  
  def setup
    @person, @second_person, @third_person = Person.forge, Person.forge, Person.forge
    @admin_person = Person.forge(:admin_id => Admin.create(:manage_messages => true).id)
    @group = Group.create! :name => 'Some Group', :category => 'test'
    @group.memberships.create! :person => @person
  end

  should "create a new message with attachments" do
    files = [fixture_file_upload('files/attachment.pdf')]
    @message = Message.create_with_attachments({:to => @person, :person => @second_person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph}, files)
    assert_equal 1, @message.attachments.count
  end
  
  should "preview a message" do
    subject, body = Faker::Lorem.sentence, Faker::Lorem.paragraph
    @preview = Message.preview(:to => @person, :person => @second_person, :subject => subject, :body => body)
    assert_equal subject, @preview.subject
    @body = get_email_body(@preview)
    assert @body.index(body)
    assert @body.index('Hit "Reply" to send a message')
    assert @body.index(/http:\/\/.+\/privacy/)
  end
  
  should "know who can see the message" do
    # group message
    @message = Message.create(:group => @group, :person => @person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph)
    assert @person.can_see?(@message)
    assert !@second_person.can_see?(@message)
    assert @admin_person.can_see?(@message)
    # group message in private group
    @group.update_attributes! :private => true
    assert !@third_person.can_see?(@message)
    assert !@admin_person.can_see?(@message)
    # wall message
    @message = Message.create(:wall => @person, :person => @second_person, :subject => 'Wall Post', :body => Faker::Lorem.paragraph)
    assert @person.can_see?(@message)
    assert @second_person.can_see?(@message)
    assert @third_person.can_see?(@message)
    # wall message with wall disabled
    @person.update_attributes! :wall_enabled => false
    assert @person.can_see?(@message)
    assert !@second_person.can_see?(@message)
    assert !@third_person.can_see?(@message)
    # private message
    @message = Message.create(:to => @second_person, :person => @person, :subject => Faker::Lorem.sentence, :body => Faker::Lorem.paragraph)
    assert @person.can_see?(@message)
    assert @second_person.can_see?(@message)
    assert !@third_person.can_see?(@message)
  end
end
