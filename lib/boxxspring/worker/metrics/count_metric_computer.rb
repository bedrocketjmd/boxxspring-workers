class CountMetricComputer < MetricComputer
  
  def to_json
    {
      metric_name: name,
      dimensions: dimensions,
      value: compute_value,
      unit: unit.to_s.capitalize
    }
  end

  private; def compute_value
    @value.floor
  end

end
