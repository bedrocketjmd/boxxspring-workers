class MetricComputer

  PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
  PERMITTED_METRIC_UNITS =  { 
      "counted": [ :count ], 
      "timed": [ :microseconds ] 
    } 
  

  def dimensions
    @dimensions ||= {}
  end

  def name
    @name ||= ""
  end
  
  def value
    @value ||= 1
  end
  
  def unit
    @unit ||= ""
  end

  def initialize( hash, dimensions )
    @name, @value, @unit = hash.values
    @dimensions = dimensions

    unless name.in?( PERMITTED_METRIC_NAMES ) && \
      unit.in?( PERMITTED_METRIC_UNITS.values.flatten )
      
      raise "A metric #{ name } #{ value } #{ unit } is not permitted."
    
    end
  end

  def start
    unit.in?( PERMITTED_METRIC_UNITS[ :counted ] ) ? increment : \
      @value = Time.now
  end

  def stop 
    unless unit.in?( PERMITTED_METRIC_UNITS[ :counted ] )
      @value = Time.now - @value
    end
  end

  def increment
    @value += @value 
  end

end

