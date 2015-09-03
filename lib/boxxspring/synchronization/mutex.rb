module Boxxspring
  module Synchronization

    class Mutex 

      def initialize( name, signature = nil )
        @orchestrator = Synchronization::Orchestrator.instance
        @name = name
        @signature = signature || SecureRandom.hex
      end

      def lock( options = {} )
        @orchestrator.lock( @name, @signature, options )
      end

      def unlock
        @orchestrator.unlock( @name, @signature )
      end

    end

  end

end
