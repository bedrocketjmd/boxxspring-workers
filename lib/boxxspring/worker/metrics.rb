require 'thread'
require 'pry'

module Boxxspring
  module Worker
    module Metrics





        # WORKER
  #     dimensions = {
  #                    name: 'WorkerName',
  #                    value: queue_name
  #                  },
  #                  {
  #                    name: 'Environment',
  #                    value: environment
  #                  }

  #      metric "Invocations" => :count, "Other Metric" => :duration do 
  #        #process task
  #        metric "Failure" => :count

  #      rescue Error => e 
  #        metrics "Errors" => :count
  #      end
         # WORKER
        





      PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
      PERMITTED_METRIC_UNITS = [ "Count" ]
      
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
      end

      #Get dimensions from worker...
      def dimensions
        @dimensions ||= dimensions
      end

      def initialize_metrics_count
        @metrics ||= refresh_metrics_count
      end

      def initiailize
        binding.pry
        initialize_metrics_count

        Thread.new do
          while true 
            if MUTEX.lock()
              unless METRICS.empty?
                
                @client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: format_metrics( METRICS )
                } )

              end
            end

            @metrics = refresh_metrics_count
            MUTEX.sleep(1);
          end
        end
      end

      def metric ( *args )
        Thread.new do
          begin
            yield if block_given?  
            
            if MUTEX.lock()
              args.each do | metric_hash |
                name = metric_hash.key
                unit = metric_hash[ name ]

                if name.in?( PERMITTED_METRIC_NAMES ) && unit.in?( PERMITTED_METRIC_UNITS )
                  METRICS[ name ][ unit ] = METRICS[ name ][ unit ] + 1 
                end

              end
            end
          ensure
            MUTEX.unlock();
          end

        end
      end

      protected; def refresh_metrics_count
        Hash[ PERMITTED_METRIC_NAMES.map { | name |
          [ name, Hash[ PERMITTED_METRIC_UNITS.map { | unit |
            [ unit, 0 ]
           } ] ] 
        } ]
      end

      protected; def format_metrics ( counts )
        formatted_metrics = []

        METRICS.each do | name, units_hash |
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
