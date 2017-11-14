require 'thread'
require 'benchmark'

module Boxxspring
  module Worker
    module Metrics
      
      PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
      PERMITTED_METRIC_UNITS = [ :count, :milliseconds ]
      
      MUTEX = Mutex.new 

      def client
        @client ||= Aws::CloudWatch::Client.new
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

        args.key?( :defaults ) ? @dimensions = args[ :defaults ] \
          : @dimensions = defaults
      end

      def initialize_metrics_hash
        @metrics ||= refresh_metrics_hash
      end

      def initialize
        initialize_metrics_hash

        Thread.new do
          loop do             
            unless @metrics[ "empty" ]
              
              MUTEX.synchronize do 
                metrics_payload = Hash.new( @metrics )
                @metrics = refresh_metrics_hash
              end

              begin
                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: format_metrics_hash( metrics_payload )
                } )

              rescue
                raise "An error has occured when making a request to the AWS Cloudwatch endpoint 'put_metric_data'."
              end

              sleep 1 
            end
          end
        end
      end


      #metric "Invocations", :seconds
        #one invocation, tracking seconds
      #metric ( [ "Invocations", 1, :seconds ], [ "Failures", 1 ] )
        #multiple metrics
      #metric "Error", 2, :megabits
        #two megabits as an error point 


      #always put timer as the first metric if passing many
      #metric (name, optional int, optional unit) - can be array
      def metric ( *args )
        time_elapsed = nil
        args = [ args ] unless args.first.is_a? Array
        
        args.each_with_index do | m, i |
          block_given? ? time_elapsed = metric_with_block( m, i, &block ) \  
            metric_without_block( m )
          
          add_metric_to_hash( parse_metric( m, time_elapsed ) )
        end
      end

      def metric_with_block ( metric, *index, &block )
       metric = parse_metric( metric )

       #Per metric given as parameter (metric Invocations :count)
        computers = metrics.map do | metric |
          computer_class =
            "#{ metric[ :unit ].to_s.capitalize }MetricComputer".constantize
          computer_class.new( metric[ :name ], options )
        end

        computer.each( &:start )
        yield block if block_given?
        computer.each( &:stop )

        payload = computers.map( &:to_json )

       
       metric[ :unit ] != :count && index == 0 ? \
         Benchmark.realtime( yield ) : nil
      end

      def metric_without_block ( metric )
        metric = parse_metric( metric )
        
        unless metric[ :unit ] == :count
          raise "This unit type requires a block."
        end
      end

      def parse_metric ( arr, time = nil ) 
        name, data, unit = arr.first, 1, :count
        
        data = time unless time.nil?
        data = arr[ 2 ] if arr[ 2 ].is_a? Integer 
        unit = arr[ 3 ] unless arr[ 3 ].nil?

        return { name: name, data: data, unit: unit }
      end

      def add_metric_to_hash ( metric )
        name, data, unit = metric.values
         
        MUTEX.synchronize do
          args.each do | metric_hash |
            if name.in?( PERMITTED_METRIC_NAMES ) && unit.in?( PERMITTED_METRIC_UNITS )
              @metrics[ "empty" ] = false
              
              unit = unit.to_s.capitalize 
              
              unless data
                @metrics[ name ][ unit ] = @metrics[ name ][ unit ] + 1 
              else
                @metrics[ name ][ unit ] = data
              end

            end
          end
        end
      end

      protected; def refresh_metrics_hash
        hash = Hash[ PERMITTED_METRIC_NAMES.map { | name |
          [ name, Hash[ PERMITTED_METRIC_UNITS.map { | unit |
            [ unit.to_s.capitalize, 0 ]
           } ] ] 
        } ]
        
        hash[ "empty" ] = true
        
        hash
      end

      protected; def format_metrics_hash ( counts )
        formatted_metrics = []
        @metrics.delete( 'empty' )

        @metrics.each do | name, units_hash |
          units_hash.each do | unit, val |
            if count > 0

              formatted_metrics << { 
                metric_name: name,
                dimensions: @dimensions,
                value: val,
                unit: unit
              }
            
            end
          end
        end

        formatted_metrics
      end

    end
  end
end
