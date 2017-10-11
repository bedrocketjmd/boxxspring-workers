module Boxxspring
  module Worker
    module Metrics

      #Example call
      metric "Invocations", :value => 1 do 
        # stuff happens here 
        
      end




      def initialize
        @client ||= Aws::CloudWatch::Client.new
      end

      def metric ( name, value: )
        # Messages Invocations Failures Errors
        
        data = yield
        
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

        @client.put_metric_data( {
          namespace: 'Unimatrix/Worker',
          metric_data: [ obj ]
        } )

      end

    end
  end
end
