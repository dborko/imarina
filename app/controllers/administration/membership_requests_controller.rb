class Administration::MembershipRequestsController < ApplicationController
  before_filter :only_admins
  
  def index
    @reqs_by_group = MembershipRequest.find(:all).group_by &:group
  end

  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_groups)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
