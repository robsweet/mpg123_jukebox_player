class Track
  attr_reader :file_location, :end_time
  attr_accessor :start_time

  def initialize params
    raise if params.nil?
    @file_location = params[0]
    @start_time = params[1].to_f if params[1]
    @end_time = params[2].to_f if params[2]
    @after = params[3] == 'pause'
  end

  def pause_after?
    @after 
  end

end
