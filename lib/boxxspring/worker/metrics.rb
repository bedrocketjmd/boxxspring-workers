require 'thread'

module Boxxspring
  
  module Worker
  
    module Metrics
      
      METRICS_MUTEX = Mutex.new 
      
      def metrics_client
        @metrics_client ||= Aws::CloudWatch::Client.new
      end

      def dimensions
        @dimensions ||= []
      end
      
      def initialize( *args )
        super

        @metrics = []

        Thread.new do
          loop do 
            unless @metrics.empty?
              begin
                metrics_payload = nil 
                
                METRICS_MUTEX.synchronize do
                  metrics_payload = @metrics
                  @metrics = []
                end

                metrics_client.put_metric_data( {
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
        new_dimensions = []
        schema = {
                   name: "",
                   value: ""
                 }
        
        dimensions.last.each{ | d | new_dimensions << d.dup } \
          unless dimensions.empty?

         args.each do | k, v |
           dimension = schema.clone
           dimension[ :name ] = k.to_s.camelize
           dimension[ :value ] = v

           new_dimensions << dimension
         end

         dimensions.push new_dimensions
         yield if block_given?
         dimensions.pop
      end


      #metric :invocations, :seconds
      #metric ( [ :invocations", 1, :seconds ], [ :failures, 1 ] )
      #metric error, 2, :count

      def metric ( *args )
        args = [ args ] unless args.first.is_a? Array
        computers = args.map do | metric |
          parsed_metric = parse_metric( metric )  

          computer_class =
            "#{ parsed_metric[ :unit ].to_s.capitalize }MetricComputer".constantize
          computer_class.new( parsed_metric, @dimensions.last )
        end

        if block_given?
          computers.each( &:start )
          yield
          computers.each( &:stop )
        end

        METRICS_MUTEX.synchronize do
          @metrics = @metrics.concat( 
            computers.map( &:to_json ).delete_if { | json | json.blank? } 
          ) 
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
