# == Schema Information
#
# Table name: services
#
#  id                  :integer       not null, primary key
#  person_id           :integer       not null
#  service_category_id :integer       not null
#  status              :string(255)   default("current"), not null
#  site_id             :integer       
#  created_at          :datetime      
#  updated_at          :datetime      
#

class Service < ActiveRecord::Base
  belongs_to :person
  belongs_to :service_category
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
end
