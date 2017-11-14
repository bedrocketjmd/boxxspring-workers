class MicrosecondsMetricComputer < MetricComputer
  
  private; def compute_value
   @value = @value * 1000000
  end

end
