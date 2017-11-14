class MicrosecondsMetricComputer < MetricComputer
  
  def to_json
    {
      metric_name: name,
      dimensions: dimensions,
      value: compute_value,
      unit: unit
    }
  end

  private; def compute_value
    @value * 1000000
  end

end
