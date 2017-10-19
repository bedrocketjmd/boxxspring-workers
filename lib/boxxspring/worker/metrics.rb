require 'thread'

module Boxxspring
  module Worker
    module Metrics
      
      PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
      PERMITTED_METRIC_UNITS = [ "Count", "Duration" ]
      
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
      end
      
      def dimensions
        @dimensions ||= {}
      end

      def initialize_metrics_count
        @metrics ||= refresh_metrics_count
      end

      def initialize
        initialize_metrics_count

        Thread.new do
          while true 
            if MUTEX.lock()
              unless @metrics[ "empty" ]
                
                @client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: format_metrics( @metrics )
                } )

              end
            end

            @metrics = refresh_metrics_count
            MUTEX.sleep(1);
          end
        end
      end

      def metric ( *args, dimensions: = nil )
        Thread.new do
          begin
            if MUTEX.lock()
              @dimensions = dimensions if !dimensions.nil?

              args.each do | metric_hash |
                name = metric_hash.key
                unit = metric_hash[ name ]

                if name.in?( PERMITTED_METRIC_NAMES ) && unit.in?( PERMITTED_METRIC_UNITS )
                  @metrics[ "empty" ] = false
                  @metrics[ name ][ unit ] = @metrics[ name ][ unit ] + 1 
                end

              end
            end
          ensure
            MUTEX.unlock();
            yield if block_given?  
          
          end
        end
      end

      protected; def refresh_metrics_count
        hash = Hash[ PERMITTED_METRIC_NAMES.map { | name |
          [ name, Hash[ PERMITTED_METRIC_UNITS.map { | unit |
            [ unit, 0 ]
           } ] ] 
        } ]
        
        hash[ "empty" ] = true
        
        hash
      end

      protected; def format_metrics ( counts )
        formatted_metrics = []

        @metrics.each do | name, units_hash |
          units_hash.each do | unit, count |
          
            formatted_metrics << { 
              metric_name: name,
              dimensions: @dimensions,
              value: count,
              unit: unit
            }
          end
        end
        formatted_metrics
      end

    end
  end
end
