# == Schema Information
#
# Table name: verifications
#
#  id           :integer       not null, primary key
#  email        :string(255)   
#  mobile_phone :string(25)    
#  code         :integer       
#  verified     :boolean       
#  created_at   :datetime      
#  updated_at   :datetime      
#  site_id      :integer       
#

class Verification < ActiveRecord::Base
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"

  # generates security code
  def before_create
    conditions = ['created_at >= ? and email = ?', Date.today, email]
    if Verification.count('*', :conditions => conditions) >= MAX_DAILY_VERIFICATION_ATTEMPTS
      errors.add_to_base 'You have exceeded the daily limit for verification attempts.'
      return false
    else
      begin
        code = rand(999999)
        write_attribute :code, code
      end until code > 0
    end
  end
  
  def pending?
    read_attribute(:verified).nil?
  end
end
