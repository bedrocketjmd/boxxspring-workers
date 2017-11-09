require 'thread'

module Boxxspring
  module Worker
    module Metrics
      
      PERMITTED_METRIC_NAMES = [ "Messages", "Invocations", "Failures", "Errors" ]
      PERMITTED_METRIC_UNITS = [ :count, :seconds, :megabit ]
      
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
          loop do             
            unless @metrics[ "empty" ]
              
              MUTEX.synchronize do 
                metrics_payload = Hash.new( @metrics )
                @metrics = refresh_metrics_count
              end

              begin
                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: format_metrics( metrics_payload )
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

      #metric (name, optional int, optional unit) - can be array
      def metric ( *args )
        block_given? ? metric_with_block : metric_without_block
      
        args = [ args ] unless args.first.is_a? Array

        args.each do | m |
          add_metric_to_hash( parse_metric( args ) )
        end
      end

      def metric_with_block
        #time yield if unit indicates
      end

      def metric_without_block
        #validate if unit requires block
      end

      def parse_metric ( arr ) 
        name, data, unit = arr.first, 1, :count
        
        data = arr[ 2 ] if arr[ 2 ].is_a? Integer 
        unit = arr[ 3 ] unless arr[ 3 ].nil?

        return name, data, unit
      end

      def add_metric_to_hash ( arr )
        name, data, unit = arr
         
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

      protected; def refresh_metrics_count
        hash = Hash[ PERMITTED_METRIC_NAMES.map { | name |
          [ name, Hash[ PERMITTED_METRIC_UNITS.map { | unit |
            [ unit.to_s.capitalize, 0 ]
           } ] ] 
        } ]
        
        hash[ "empty" ] = true
        
        hash
      end

      protected; def format_metrics ( counts )
        formatted_metrics = []
        @metrics.delete( 'empty' )

        @metrics.each do | name, units_hash |
          units_hash.each do | unit, count |
            if count > 0

              formatted_metrics << { 
                metric_name: name,
                dimensions: @dimensions,
                value: count,
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
