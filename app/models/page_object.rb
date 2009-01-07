class PageObject < ActiveRecord::Base
  include ThriveSmartObjectMethods
  self.caching_default = "data_update[events]" #[in :forever, :page_update, :any_page_update, 'data_update[datetimes]', :never, 'interval[5]']
  self.caching_scope_default = 'request_param[page]' #[in '', 'request_param[month]'] - a new cached object will be created for each scope value

  attr_accessor :page, :total_page_count, :events
  
  def upcoming_events
    @upcoming_events ||= self.events.reject {|e| e.end <= Time.now}.sort { |x,y| x.start <=> y.start }
  end
  
  def past_events
    @past_events ||= self.events.reject {|e| e.end > Time.now}.sort { |x,y| y.start <=> x.start }
  end
  
  def fetch_events(attrs = {})
    self.page = page_query_parameters[:page] || 1
    
    self.events = self.organization.find_data(:events, 
      :include => [:url, :start, :end, :name, :description, :picture], 
      :conditions => {  :start => { :page => page }, 
                        :end => { :page => page } })

    self.total_page_count = events.first.respond_to?(:page_count) ? events.first.page_count : 1 
    parse_event_times
  end
  
  protected
    # Switches the event time and dates to times
    def parse_event_times
      Time.zone = self.time_zone if self.time_zone
      events.each do |e|
        e.start = Time.zone.parse(e.start) if e.start
        e.end = Time.zone.parse(e.end) if e.end
        logger.debug("ERROR: Empty start (#{e.start}) or end (#{e.end}) for event #{e.inspect}  ") if !e.start || !e.end
      end
    end
end
