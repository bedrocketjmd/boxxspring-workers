class MetricComputer

  def name
    @name ||= ""
  end

  def dimensions
    @dimensions ||= {}
  end
  
  def value
    @value ||= 0
  end
  
  def unit
    @unit = self.class.name.split('::').first
  end

  def initialize( name, dimensions )
    @name = name
    @dimensions = dimensions
  end

  def start
    @value = Time.now
  end

  def stop
    @value -= Time.now
  end

  def increment( value )
    @value += value
  end

  def to_json
    {
      metric_name: name,
      dimensions: dimensions,
      value: compute_value,
      unit: unit
    }
  end

end

