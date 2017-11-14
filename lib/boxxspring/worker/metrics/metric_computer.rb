class MetricComputer

  PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
  PERMITTED_METRIC_UNITS = [ :count, :microseconds ]

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
    if name.in?( PERMITTED_METRIC_NAMES ) && unit.in?( PERMITTED_METRIC_UNITS )
      @name, @value, @unit = hash.values
      @dimensions = dimensions
    
    else
      raise "A metric #{ name, unit, value } is not permitted."
    
    end
  end

  def start
    @value = Time.now
  end

  def stop
    @value -= Time.now
  end

  def increment
    @value += @value
  end

end

