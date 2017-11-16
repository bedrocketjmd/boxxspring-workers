class MetricComputer

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
  end

  def to_json
    {
      metric_name: name.to_s.capitalize,
      dimensions: dimensions,
      value: value.to_i,
      unit: unit.to_s.capitalize
    }
  end
end

