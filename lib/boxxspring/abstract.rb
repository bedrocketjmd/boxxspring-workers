module Boxxspring

  class Abstract

    def initialize( attributes = {} )
      @attributes = {}
      attributes.each_pair do | key, value |
        self.send( key, value )
      end
    end

    def to_hash
      return @attributes
    end

    def method_missing( method, *arguments, &block )
      result = nil
      if arguments.length == 0 
        result = @attributes[ method.to_sym ] 
        if result.nil? 
          result = Abstract.new
          result.instance_eval( &block ) unless block.nil?
          @attributes[ method.to_sym ] = result 
        end 
      elsif arguments.length == 1
        method = method.to_s.gsub( /=$/, '' )
        result = arguments[ 0 ]
        @attributes[ method.to_sym ] = result 
      else
        result = super 
      end
      result
    end    

  end

end