require 'thread'

module Boxxspring
  module Worker
    module Metrics
      
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
      end
      
      def initialize_metrics
        @metrics = []
      end
      
      def initialize
        initialize_metrics

        Thread.new do
          loop do 
            unless @metrics.empty?
              begin
                metrics_payload = []
                
                MUTEX.synchronize do 
                  jsonified = @metrics.map( &:to_json )
                  jsonified.each{ | m | metrics_payload << m.dup }
                  initialize_metrics
                end

                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: metrics_payload
                } )

              rescue Error => e
                raise "An error has occured when making a request to the AWS
                  Cloudwatch endpoint 'put_metric_data'."
              end

              sleep 1 
            end
          end
        end
      end

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
      end


      #metric "Invocations", :seconds
      #metric ( [ "Invocations", 1, :seconds ], [ "Failures", 1 ] )
      #metric "Error", 2, :megabits

      def metric ( *args )
        args = [ args ] unless args.first.is_a? Array
        dimensions = metric_defaults name: self.human_name, env: environment
        
        MUTEX.synchronize do 
          new_metrics = args.map do | m |
            m = parse_metric( m )
            
            computer_class =
              "#{ m[ :unit ].to_s.capitalize }MetricComputer".constantize
            computer_class.new( m, dimensions )
          end

          @metrics.concat new_metrics
 
          if block_given?
            @metrics.each( &:start )
            yield
            @metrics.each( &:stop )
          end

        end
      end

      def parse_metric ( arr )
        name, data, unit = arr.first, 1, :count

        data = arr[ 1 ] if arr[ 1 ].is_a? Integer
        unit = arr[ 1 ] if arr[ 1 ].is_a? Symbol
        unit = arr[ 2 ] unless arr[ 2 ].nil?

        { name: name, data: data, unit: unit }
      end

    end
  end
end
