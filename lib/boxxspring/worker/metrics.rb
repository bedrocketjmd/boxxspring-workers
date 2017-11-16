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
      
      def dimensions
        @dimensions ||= []
      end
      
      def initialize
        initialize_metrics

        Thread.new do
          loop do 
            unless @metrics.empty?
              begin
                idle_metrics = []
                running_metrics = []
                
                MUTEX.synchronize do
                  @metrics.each{ | m | idle_metrics << m.dup }
                  
                  idle_metrics.delete_if do | m |
                    running_metrics << m.dup if !m.idle?
                    !m.idle?
                  end

                  idle_metrics = idle_metrics.map( &:to_json )
                  @metrics = running_metrics
                end

                client.put_metric_data( {
                  namespace: 'Unimatrix/Worker',
                  metric_data: idle_metrics
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

      def set_metric_defaults( **args )
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
      end


      #metric :invocations, :seconds
      #metric ( [ :invocations", 1, :seconds ], [ :failures, 1 ] )
      #metric error, 2, :count

      def metric ( *args )
        args = [ args ] unless args.first.is_a? Array

        MUTEX.synchronize do
          new_metrics = args.map do | m |
            m = parse_metric( m )
            
            computer_class =
              "#{ m[ :unit ].to_s.capitalize }MetricComputer".constantize
            computer_class.new( m, @dimensions.last )
          end
            
          @metrics.concat new_metrics
        end

        if block_given?
          @metrics.each( &:start )
          yield
          @metrics.each( &:stop )
        end

        @dimensions.pop
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
