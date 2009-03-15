# == Schema Information
# Schema version: 20080709134559
#
# Table name: checkin_attendance_records
#
#  id             :integer       not null, primary key
#  person_id      :integer       
#  site_id        :integer       
#  barcode_id     :string(50)    
#  first_name     :string(255)   
#  last_name      :string(255)   
#  family_name    :string(255)   
#  age            :string(255)   
#  section        :string(255)   
#  in             :datetime      
#  out            :datetime      
#  void           :boolean       
#  can_pick_up    :string(100)   
#  cannot_pick_up :string(100)   
#  medical_notes  :string(200)   
#  created_at     :datetime      
#  updated_at     :datetime      
#

class CheckinAttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  class << self
    def check(person, section)
      today = Date.today
      if prev_record = person.checkin_attendance_records.find(:first, :conditions => ['section = ? and `in` >= ? and `out` is null and void = ?', section, today, false])
        prev_record.update_attribute :out, Time.now
        prev_record
      else
        person.checkin_attendance_records.create(:barcode_id => person.barcode_id, :first_name => person.first_name, :last_name => person.last_name, :family_name => person.family.name, :age => person.age_group, :section => section, :in => Time.now, :can_pick_up => person.can_pick_up, :cannot_pick_up => person.cannot_pick_up, :medical_notes => person.medical_notes) rescue nil
      end
    end
  end
end

Person.class_eval do
  has_many :checkin_attendance_records
  def age_group
    if ag = classes.split(',').detect { |c| c =~ /^AG:/ }
      ag.split(':').last
    end
  end
end
