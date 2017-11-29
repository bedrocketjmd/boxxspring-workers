class MetricComputer
  
  def name
    @name ||= ""
  end
  
  def value
    @value ||= 1
  end
  
  def unit
    @unit ||= ""
  end

  def initialize( hash, defaults )
    @name, @value, @unit = hash.values
    @defaults = defaults
  end

  def to_json
    {
      metric_name: name.to_s.capitalize,
      dimensions: normalize_dimensions_from_defaults( @defaults ),
      value: value.to_i,
      unit: unit.to_s.capitalize
    }
  end

  private; def normalize_dimensions_from_defaults( defaults )
    return nil if defaults[ :dimensions ].blank?
    
    defaults[ :dimensions ].map do | key, value |
      {
        name: key.to_s.camelize,
        value: value 
      }
    end 

  end

end

