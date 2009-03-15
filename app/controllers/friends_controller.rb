class FriendsController < ApplicationController

  cache_sweeper :friendship_sweeper, :only => %w(create update destroy reorder)

  before_filter :person_must_be_user, :except => %w(index)
  
  def index
    @person = Person.find(params[:person_id])
    if @logged_in.can_see?(@person)
      @pending = me? ? @person.pending_friendship_requests : []
      @friendships = @person.friendships.all.select { |f| f.friend and @logged_in.can_see?(f.friend) }
    else
      render :text => 'Person not found.', :layout => true, :status => 404
    end
  end
  
  # friend_id = Person (other person)
  def create
    @person = Person.find(params[:person_id])
    @other_person = Person.find(params[:friend_id])
    @message = @person.request_friendship_with(@other_person)
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  # id = FriendshipRequest
  def update
    @person = Person.find(params[:person_id])
    @friendship_request = @person.friendship_requests.find(params[:id])
    if params[:accept]
      @friendship_request.accept
      flash[:notice] = 'Friendship accepted.'
      redirect_to person_friends_path(@person)
    elsif params[:reject]
      @friendship_request.reject
      flash[:notice] = 'Friendship rejected.'
      redirect_to person_friends_path(@person)
    else
      render :text => 'Must specify accept=true or reject=true', :layout => true, :status => 500
    end
  end
  
  # id = Person (friend)
  def destroy
    @person = Person.find(params[:person_id])
    if @friendship = @person.friendships.find_by_friend_id(params[:id])
      @friendship.destroy
      redirect_to person_friends_path(@person)
    else
      render :text => 'Friend not found.', :layout => true, :status => 404
    end
  end
  
  def reorder
    @person = Person.find(params[:person_id])
    params[:friends].each_with_index do |id, index|
      if f = @person.friendships.find_by_id(id)
        f.update_attribute :ordering, index
      end
    end
    render :nothing => true
  end
  
  private
  
    def person_must_be_user
      unless @logged_in.id == params[:person_id].to_i
        render :text => 'You may not manage friendships for anyone but yourself.', :layout => true, :status => 401
        return false
      end
    end

end
