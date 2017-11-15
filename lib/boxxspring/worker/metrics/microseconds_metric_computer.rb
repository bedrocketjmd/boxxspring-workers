class MicrosecondsMetricComputer < MetricComputer
  
  def value 
    @value * 1000000
  end

  def start
    @start_time = Time.now
    @state = "running"
  end

  def stop 
    @value = Time.now - @start_time
    @state = "idle"
  end

end
