class MillisecondsMetricComputer < MicrosecondsMetricComputer
  
  def value 
    super / 1000
  end

end
