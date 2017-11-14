require 'thread'
require 'benchmark'

module Boxxspring
  module Worker
    module Metrics
      
      MUTEX = Mutex.new 

      def metrics
        @metrics ||= {}
      end

      def client
        @client ||= Aws::CloudWatch::Client.new
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

      def initialize
        refresh_metrics_hash

        Thread.new do
          loop do 
            unless @metrics.empty?
              
              MUTEX.synchronize do 
                #copy
                metrics_payload = Hash.new( @metrics )
                #refresh
                @metrics = refresh_metric_computers
              end

              begin
                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: metrics
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


      #metric "Invocations", :seconds
      #metric ( [ "Invocations", 1, :seconds ], [ "Failures", 1 ] )
      #metric "Error", 2, :megabits

      #Step 2
      def metric ( *args )
        args = [ args ] unless args.first.is_a? Array
        
          #If computer does not exsist, create, else access existing
          #These computers are @metrics
          #Does this need to be mutex locked?
        computers = args.map do | metric |
          metric = parse_metric( metric )
          
          computer_class =
            "#{ metric[ :unit ].to_s.capitalize }MetricComputer".constantize
          computer_class.new( metric, @dimensions )
        end

        if block_given?
          computers.each( &:start )
          yield 
          computers.each( &:stop )
        else
          computers.each( &:increment )
        end

        @metrics = computers.map( &:to_json )
      end

      def parse_metric ( arr )
        name, data, unit = arr.first, 1, :count

        data = arr[ 2 ] if arr[ 2 ].is_a? Integer
        unit = arr[ 3 ] unless arr[ 3 ].nil?

        { name: name, data: data, unit: unit }
      end

      def wipe_metrics_computers
      end

      def copy_metrics_computers
      end

    end
  end
end
