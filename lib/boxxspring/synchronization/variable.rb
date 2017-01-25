module Boxxspring
  module Synchronization

    class Variable 

      def initialize( name )
        @orchestrator = Synchronization::Orchestrator.instance
        @name = name
      end

      def read( options={} )
        @orchestrator.read( @name, options )
      end

      def write( value, options={} )
        @orchestrator.write( @name, value, options )
      end

      def write_if_condition( value, condition )
        @orchestrator.write_if_condition( @name, value, condition )
      end

    end

  end
end
