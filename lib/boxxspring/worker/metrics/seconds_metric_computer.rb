class SecondsMetricComputer < MicrosecondsMetricComputer
  
  def value 
    super / 1000000
  end

end
