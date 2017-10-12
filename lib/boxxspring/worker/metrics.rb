require 'thread'

module Boxxspring
  module Worker
    module Metrics


       #WORKER
         dimensions = {
                        name: 'WorkerName',
                        value: queue_name
                      },
                      {
                        name: 'Environment',
                        value: environment
                      }

          metric "Invocations" => :count, "Duration" => :duration, dimensions: dimensions do 
            #process task
            metric "Failure" => :count, dimensions: dimensions

          rescue Error => e 
            metrics "Errors" => :count, dimensions: dimensions
          end
        #WORKER
        




      PERMITTED_METRIC_VALUES = [ "Messages", "Invocations", "Failures", "Errors" ]
      METRICS = Hash[ a.map { |v| [ v,{} ] } ]
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
      end

      #Get dimensions from worker...
      def dimensions
        @dimensions ||= dimensions
      end

      def initiailize
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

            METRICS = {}
            MUTEX.sleep(1);
          end
        end
      end

      def metric ( *metric_hashes )
        Thread.new do
          begin
            if MUTEX.lock()
              yield &block if block_given?

              #parse & validate metrics hashes - then incriment counts (init at 0 if not present)
              #Example: Invocations is the name, unit is count
              
              METRICS[ name ][ unit ] = METRICS[ name ][ unit ]++; 
            end
          ensure
            MUTEX.unlock();
          end
        end
      end

      protected; def format_metrics ( counts )
        #loop through METRICS counts and format each object per PERMITTED METRIC VALUE

        obj = { 
          metric_name: name,
          dimensions: @dimensions
          value: METRICS[ name ][ unit ],
          unit: unit
        }

        #returning an array of formated metrics
      end

    end
  end
end
