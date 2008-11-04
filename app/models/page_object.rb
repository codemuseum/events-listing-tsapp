class PageObject < ActiveRecord::Base
  include ThriveSmartObjectMethods
  self.caching_default = "data_update[events]" #[in :forever, :page_update, :any_page_update, 'data_update[datetimes]', :never, 'interval[5]']
  self.caching_scope_default = 'request_param[page]' #[in '', 'request_param[month]'] - a new cached object will be created for each scope value

  attr_accessor :page, :events
  
  
  def upcoming_events
    @upcoming_events ||= self.events.reject {|e| e.end > Time.now}.sort { |x,y| x.start <=> y.start }
  end
  
  def past_events
    @past_events ||= self.events.reject {|e| e.end <= Time.now}.sort { |x,y| y.start <=> x.start }
  end
  
  def fetch_events(attrs = {})
    Time.zone = self.time_zone if self.time_zone
    self.page = page_query_parameters[:page]
    
    self.events = self.organization.find_data(:events, 
      :include => [:url, :start, :end, :name, :description, :picture], 
      :conditions => {  :start => { :page => page }, 
                        :end => { :page => page } })
  end
end
