module Boxxspring 

  module Worker

    QUEUE_MESSAGE_REQUEST_COUNT   = 10
    QUEUE_MESSAGE_WAIT_IN_SECONDS = 4

    class Base

      #------------------------------------------------------------------------
      # class attributes

      class_attribute :queue_name
      class_attribute :processor

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
          unless @queue_url.present?
            response = self.queue_interface.create_queue( 
              queue_name: self.full_queue_name 
            )
            @queue_url = response[ :queue_url ]       
          end
          @queue_url
        end

        protected; def full_queue_name
          name = ( Worker.env == 'development' ) ?
            ( ENV[ 'USER' ] || 'development' ) :
            Worker.env 
          name += '-' + 
                  ( self.queue_name || 
                    self.name.
                      underscore.
                      gsub( /[\/]/, '-' ).
                      gsub( /_worker\Z/, '' ) )
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
                self.process_payload( payload )
                # note: if an exception is raised the message will not be 
                #       deleted
                self.delete_message( message )
              rescue StandardError => error
                self.logger.error(
                  "The #{ self.human_name } worker failed to process the " + 
                  "payload. #{error.message}."
                )
              end
            else
              # note: messages with invalid payloads are deleted
              self.delete_message( message )
              self.logger.error(
                "The #{ self.human_name } worker received an invalid payload."
              )
            end
          end
        end
      end

      protected; def logger
        @logger ||= Boxxspring::Worker.configuration.logger
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
            "The #{ self.human_name } worker is unable to receive a message " +
            "from the queue. #{error.message}."
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
            "The #{ self.human_name } worker is unable to delete the " + 
            "message from the queue. #{error.message}."
          )
        end
        message
      end

      protected; def payload_from_message( message )
        payload = message.body
        if ( payload.present? )
          payload = JSON.parse( payload ) rescue payload 
          if ( payload.is_a?( Hash ) && 
               payload.include?( 'Type' ) && 
               payload[ 'Type' ] == 'Notification' )
            payload = payload[ 'Message' ]
            payload = payload.present? ? 
              ( JSON.parse( payload ) rescue payload ) : 
              payload
          end 
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
        queue_name_prefix = ( Worker.env == 'development' ) ?
          ( ENV[ 'USER' ] || 'development' ) : Worker.env 
       queue_name = queue_name_prefix + '-' + queue_name
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
            "The #{ self.human_name } worker was unable to delegate the " + 
            "payload to the queue name '#{ queue_name }'. #{error.message}."
          )
        end
      end

      protected; def human_name
        self.class.name.  
          underscore.
          gsub( /[\/]/, ' ' ).
          gsub( /_worker\Z/, '' )
      end

    end

  end

end
