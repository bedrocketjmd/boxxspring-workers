require 'thread'

module Boxxspring
  module Worker
    module Metrics

      # Messages Invocations Failures Errors
      METRICS = Queue.new
      THREAD_POOL_SIZE = 4





        #Example call
        metric "Invocations", :value => 1 do 
          metrics = []
          
          #..
          
          metrics << { name: "ArtifactId", value: @task.artifact_id }

          #..

          metrics
        end





      def initialize
        @client ||= Aws::CloudWatch::Client.new
      end

      def metric ( name, value: )
        obj = { 
          metric_name: name
          dimensions: [
              {
                name: 'WorkerName',
                value: queue_name
              },
              {
                name: 'Environment',
                value: @environment
              }
           ],
           value: value,
           unit: 'Count'
        }

        obj[ :dimensions ] += yield
        METRICS << obj
      end

      def log_metrics
        threads = ( 0...THREAD_POOL_SIZE ).map do
          Thread.new do
            begin
              while metric_obj = METRICS.pop( true )
                @client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: metric_obj
                } )
              end
            rescue ThreadError
            end
          end
        end

        threads.map(&:join)
      end

    end
  end
end
