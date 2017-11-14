class MetricComputer

  PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
  PERMITTED_METRIC_UNITS = [ 
    { "counted": :count }, 
    { "timed": :microseconds } 
  ]

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
    if name.in?( PERMITTED_METRIC_NAMES ) && \
      unit.in?( PERMITTED_METRIC_UNITS ).map( &:values ).flatten
      
      @name, @value, @unit = hash.values
      @dimensions = dimensions
    
    else
      raise "A metric #{ name, unit, value } is not permitted."
    
    end
  end

  def start
    unit.in?( PERMITTED_METRIC_UNITS[ "counted" ] ) ? increment : \
      @value = Time.now
  end

  def stop 
    unless unit.in?( PERMITTED_METRIC_UNITS[ "counted" ] )
      @value -= Time.now
    end
  end

  def increment
    @value += @value 
  end

end

