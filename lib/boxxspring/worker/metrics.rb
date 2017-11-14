require 'thread'

module Boxxspring
  module Worker
    module Metrics
      
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
      end
      
      def initialize_metrics
        @metrics ||= []
      end
      
      def initialize
        initialize_metrics

        Thread.new do
          loop do 
            unless @metrics.empty?
              
              MUTEX.synchronize do 
                metrics_payload = @metrics.map( &:to_json )
                initialize_metrics
              end

              begin
                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: metrics_payload
                } )

              rescue
                raise "An error has occured when making a request to the AWS
                  Cloudwatch endpoint 'put_metric_data'."
              end

              sleep 1 
            end
          end
        end
      end

      #Step 1
      def metric_defaults( **args )
        defaults = [
          {
            name: "WorkerName",
            value: args[ :name ].titleize.split( " " ).join( "" )
          },
          {
            name: "Environment",
            value: args[ :env ]
          }
        ]

        args.key?( :defaults ) ? @dimensions = args[ :defaults ] \
          : @dimensions = defaults
      end


      #metric "Invocations", :seconds
      #metric ( [ "Invocations", 1, :seconds ], [ "Failures", 1 ] )
      #metric "Error", 2, :megabits

      #Step 2
      def metric ( *args )
        args = [ args ] unless args.first.is_a? Array
        
        #If computer does not exist, create, else access existing?
        MUTEX.synchronize do 
          new_metrics = args.map do | metric |
            metric = parse_metric( metric )
            
            computer_class =
              "#{ metric[ :unit ].to_s.capitalize }MetricComputer".constantize
            computer_class.new( metric, @dimensions )
          end

          @metrics.concat new_metrics

          @metrics.each( &:start )
          yield if block_given?
          @metrics.each( &:stop )
        end

      end

      def parse_metric ( arr )
        name, data, unit = arr.first, 1, :count

        data = arr[ 2 ] if arr[ 2 ].is_a? Integer
        unit = arr[ 3 ] unless arr[ 3 ].nil?

        { name: name, data: data, unit: unit }
      end

    end
  end
end
