class NoteSweeper < ActionController::Caching::Sweeper
  observe Note

  def after_save(record)
    expire_fragment(%r{views/people/#{record.person_id}_})
  end
  
  alias_method :after_destroy, :after_save
  
end
