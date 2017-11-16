class MicrosecondsMetricComputer < MetricComputer
  
  def value 
    @value * 1000000
  end

  def start
    @start_time = Time.now
  end

  def stop 
    @value = Time.now - @start_time
  end

end
