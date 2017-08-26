require 'remote_syslog_logger'

module Boxxspring

  module Worker

    QUEUE_MESSAGE_REQUEST_COUNT   = 10
    QUEUE_MESSAGE_WAIT_IN_SECONDS = 4

    class Base

      #------------------------------------------------------------------------
      # class attributes

      class_attribute :queue_name
      class_attribute :processor
      class_attribute :environment

      #------------------------------------------------------------------------
      # class methods

      class << self

        public; def process( &block )
          self.processor = block
        end

        def queue_interface
          @queue_interface ||= Aws::SQS::Client.new
        end

        def queue_url
          @queue_url ||= begin
            response = self.queue_interface.create_queue(
              queue_name: self.full_queue_name
            )
            response[ :queue_url ]
          end
        end

        def environment
          @environment ||= begin
            Worker.env == 'development' ?
              ( ENV[ 'USER' ].underscore || 'development' ) :
              Worker.env
          end
        end

        protected; def full_queue_name
          queue_name = self.queue_name ||
                       self.name.underscore.gsub( /[\/]/, '-' ).
                         gsub( /_worker\Z/, '' )
          self.environment + '-' + queue_name
        end

      end

      #------------------------------------------------------------------------
      # operations

      def process
        messages = self.receive_messages() || []
        messages.each do | message |
          if message.present?
            payload = self.payload_from_message( message )

            if payload.present?
              begin
                result = self.process_payload( payload )
                # note: if an exception is raised the message will be deleted
                self.delete_message( message ) unless result == false
              rescue StandardError => error
                self.logger.error(
                  "The #{ self.human_name } failed to process the payload."
                )
                self.logger.error( error.message )
                self.logger.info( error.backtrace.join( "\n" ) )
              end
            else
              self.delete_message( message )
              self.logger.error(
                "The #{ self.human_name } received an invalid payload."
              )
            end
          end
        end
      end

      def logger
        @logger ||= begin
          remote_logger = ENV[ 'REMOTE_LOGGER' ] || ''

          if remote_logger.present?
            if remote_logger == 'cloudwatch'

              worker_name = human_name.gsub( ' ','_' )
              workers_env = ENV[ 'WORKERS_ENV' ]
              if workers_env == "development"
                username = ENV[ 'USER' ] || ENV[ 'USERNAME' ]
                username = username.underscore.dasherize
                cloud_group = "#{ workers_env }.#{ username }"
              else
                cloud_group = "#{ ENV[ 'LOG_SYSTEM' ] }.#{ ENV[ 'WORKERS_ENV' ] }"
              end
              cloud_stream = worker_name

              logger = CloudWatchLogger.new( {
                access_key_id: ENV[ 'AWS_ACCESS_KEY_ID' ],
                secret_access_key: ENV[ 'AWS_SECRET_ACCESS_KEY' ] },
                cloud_group,
                cloud_stream
              )

            else
              remote_host   = remote_logger.split( ':' )[0]
              remote_port   = remote_logger.split( ':' )[1].to_i

              worker_env = self.class.environment
              host_suffix = ( worker_env == 'production' ) ? '' : ".#{ worker_env }"

              logger = RemoteSyslogLogger.new(
                remote_host,
                remote_port,
                program: worker_name[0..30],
                local_hostname: "#{ ENV['LOG_SYSTEM'] }#{ host_suffix }"
              )
            end
          else
            logger = Logger.new( STDOUT )
          end

          level = ENV['LOG_LEVEL'].present? ? ENV['LOG_LEVEL'].upcase : 'INFO'
          logger.level = "Logger::#{ level }".constantize

          Boxxspring::Worker.configuration { logger( logger ) }
          Boxxspring::Worker.configuration.logger
        end
      end

      def debug_mode?
        ENV['LOG_LEVEL'].present? && ENV['LOG_LEVEL'] == 'debug'
      end

      #------------------------------------------------------------------------
      # implementation

      protected; def receive_messages
        messages = nil
        begin
          response = self.class.queue_interface.receive_message(
            queue_url: self.class.queue_url,
            max_number_of_messages: QUEUE_MESSAGE_REQUEST_COUNT,
            wait_time_seconds: QUEUE_MESSAGE_WAIT_IN_SECONDS
          )
          messages = response[ :messages ]
        rescue StandardError => error
          raise RuntimeError.new(
            "The #{ self.human_name } is unable to receive a message " +
            "from the queue. #{ error.message }."
          )
        end
        messages
      end

      protected; def delete_message( message )
        begin
          self.class.queue_interface.delete_message(
            queue_url: self.class.queue_url,
            receipt_handle: message[ :receipt_handle ]
          )
        rescue StandardError => error
          raise RuntimeError.new(
            "The #{ self.human_name } is unable to delete the " +
            "message from the queue. #{ error.message }."
          )
        end

        message
      end

      protected; def payload_from_message( message )
        payload = message.body

        if payload.present?
          payload = JSON.parse( payload ) rescue payload
          if payload.is_a?( Hash ) && payload.include?( 'Type' ) &&
             payload[ 'Type' ] == 'Notification'
            payload = payload[ 'Message' ]
            payload = payload.present? ?
              ( JSON.parse( payload ) rescue payload ) :
              payload
          end
        else
          logger.info( "Payload is empty. Message #{ message.inspect }" ) \
            if debug_mode?
        end
        payload
      end

      protected; def process_payload( payload )
        if self.class.processor.present?
          self.class.processor.call( payload )
        else
          raise RuntimeError.new(
            "The worker lacks a processor"
          )
        end
      end

      protected; def delegate_payload( queue_name, payload )
        queue_name = self.class.environment + '-' + queue_name

        begin
          response = self.class.queue_interface.create_queue(
            queue_name: queue_name
          )
          queue_url = response[ :queue_url ]

          if queue_url.present?
            self.class.queue_interface.send_message(
              queue_url: queue_url,
              message_body: payload.to_json
            )
          end
        rescue StandardError => error
          raise RuntimeError.new(
            "The #{ self.human_name } was unable to delegate the " +
            "payload to the '#{ queue_name }' queue. #{ error.message }."
          )
        end
      end

      # Meta API read & error handling
      protected; def read_object( property_id=nil, type, id, includes )
        if property_id.present?
          endpoint = "/properties/#{ property_id }/#{ type.pluralize }/#{ id }"
        else
          endpoint = "/properties/#{ id }"
        end

        object = operation( endpoint ).include( *includes ).read
        if error?( object, type.capitalize ) && object.is_a?( Array )
          object.first
        else
          object
        end
      end

      protected; def error?( object, object_class )
        class_name = "Boxxspring::#{ object_class }".constantize
        !object.is_a?( class_name ) || object.send( :errors ).present?
      end

      protected; def operation( endpoint )
        Boxxspring::Operation.new(
          endpoint,
          Boxxspring::Worker.configuration.api_credentials.to_hash
        )
      end

      protected; def human_name
        self.class.name.underscore.gsub('_', ' ')
      end

    end

  end

end
