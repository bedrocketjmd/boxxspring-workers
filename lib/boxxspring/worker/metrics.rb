require 'thread'

module Boxxspring

  module Worker

    module Metrics

      METRICS_MUTEX = Mutex.new
      METRICS_CLIENT = Aws::CloudWatch::Client.new
      METRICS_UPLOAD_INTERVAL = 0.5

      def initialize( *arguments )
        super

        @metrics = []
        @metric_defaults = [ {} ]

        Thread.new do
          upload_metrics
        end
      end

      def upload_metrics
        loop do
          unless @metrics.empty?
            begin
              metrics_payload = nil

              METRICS_MUTEX.synchronize do
                if @metrics.count > 20
                  logger.info( "Metrics queue has #{ @metrics.count } metrics" )
                end

                metrics_payload = @metrics.shift(20)
              end

              METRICS_CLIENT.put_metric_data( {
                namespace: 'Unimatrix/Worker',
                metric_data: metrics_payload
              } )

            rescue => error
              logger.error(
                "An error has occured when making a request to the AWS " +
                "Cloudwatch endpoint 'put_metric_data'. - Error message: " +
                "#{ error.message }"
              )
            end

          end

          sleep METRICS_UPLOAD_INTERVAL
        end
      end

      def metric_defaults( defaults = {} )
        previous_defaults = @metric_defaults.last
        @metric_defaults.push( previous_defaults.merge( defaults ) )

        yield
        @metric_defaults.pop

      end

      def metric ( *arguments )
        arguments = [ arguments ] unless arguments.first.is_a? Array
        computers = arguments.map do | metric |
          parsed_metric = parse_metric( metric )

          computer_class =
            "#{ parsed_metric[ :unit ].to_s.capitalize }MetricComputer".constantize
          computer_class.new( parsed_metric, @metric_defaults.last )
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

      private; def parse_metric ( unparsed_metrics )
        name, data, unit = unparsed_metrics.first, 1, :count

        data = unparsed_metrics[ 1 ] if unparsed_metrics[ 1 ].is_a? Integer
        unit = unparsed_metrics[ 1 ] if unparsed_metrics[ 1 ].is_a? Symbol
        unit = unparsed_metrics[ 2 ] unless unparsed_metrics[ 2 ].nil?

        { name: name, data: data, unit: unit }
      end

    end
  end
end
