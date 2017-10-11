module Boxxspring
  module Worker
    module Metrics

      #Example call
      metric 'Invocations' => :count, 'Errors' => :duration do 
        # stuff happens here 
      { 
        metric_name: "Invocations"
        dimensions: [
            {
              name: 'WorkerName',
              value: self.human_name.gsub( ' ','_' )
            },
            {
              name: 'Environment',
              value: ENV[ 'WORKERS_ENV' ]
            }
         ],
         value: 1,
         unit: 'Count'
      }

      end




      def initialize
        @client ||= Aws::CloudWatch::Client.new
      end

      def metric ( type )
        # Messages Invocations Failures Errors
        
        data = yield
        
        if ENV[ 'WORKERS_ENV' ] == 'development'
          username = ENV[ 'USERNAME' ].titleize.split( " " ).join( "" )
          data[ :dimensions ] << { name: 'DeveloperName', value: username }
        end

        @client.put_metric_data( {
          namespace: 'Unimatrix/Worker',
          metric_data: [ data ]
        } )
      end

    end
  end
end
