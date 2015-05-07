module Boxxspring

  class Abstract

    def initialize( attributes = {} )
      attributes.each_pair do | key, value |
        self.send( key, value )
      end
    end

    def method_missing( method, *arguments, &block )
      result = nil
      if arguments.length == 0 
        result = instance_variable_get( "@#{method}" ) 
        if result.nil? 
          result = Abstract.new
          instance_variable_set( "@#{method}", result )
        end 
      elsif arguments.length == 1
        method = method.to_s.gsub( /=$/, '' )
        result = arguments[ 0 ]
        instance_variable_set( "@#{method}", result ) 
      else
        result = super 
      end
      result
    end    

  end

end