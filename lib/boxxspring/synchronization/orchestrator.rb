require 'redis'

module Boxxspring
  module Synchronization

    class Orchestrator 

      include Singleton

      def initialize 
        @provider = ::Redis.new(
          url: Synchronization.configuration.url,
          timeout: 10.0
        )
        @operations = {}
      end

      def lock( key, signature, options = {} )
        ttl = options[ :ttl ];
        ttl = ttl * 1000 if ttl.is_a? ActiveSupport::Duration
        self.execute_operation( :lock, [ key ], [ signature, ttl ] ) ?
          true : false
      end

      def unlock( key, signature )
        self.execute_operation( :unlock, [ key ], [ signature ] ) ?
          true : false
      end

      def read( key, options = {} )
        range = options[ :range ]
        if range
          range_start = range[ :start ] || 0
          range_end   = range[ :end ] || -1
          @provider.lrange( key, range_start, range_end )
        else
          @provider.get( key )
        end
      end

      def write( key, value, options = {} )
        ttl = options[ :ttl ]
        if ttl 
          ttl = ttl.to_i if ttl.is_a? ActiveSupport::Duration
          ( @provider.set( key, value ) == "OK" ) && 
          ( @provider.expire( key, ttl ) ) ? true : false
        else
          ( @provider.set( key, value ) == "OK" ) ? true : false
        end
      end

      def write_if_condition( key, value, condition )
        operation = "write_if_#{condition}"
        operation_sha = @operations[ operation.to_sym ]
        raise 'Synchronization: An unknown condition was requested.' \
          if operation_sha.nil?
        @provider.evalsha( operation_sha, [ key ], [ value ] ) ? true : false
      end

      protected; def execute_operation( operation, keys, arguments )
        try ||= 1
        sha = @operations[ operation ] || install_operation( operation )
        @provider.evalsha( sha, keys, arguments ) ? true : false
      rescue Redis::CommandError => error
        raise error unless error.message.match( /\ANOSCRIPT/ )
        self.install_operation( operation )
        retry if ( try -= 1 ) >= 0
      end

      protected; def install_operation( operation )
        @operations[ operation ] = @provider.script( 
          :load, 
          Operations[ operation ] 
        )
      end

    end

  end

end