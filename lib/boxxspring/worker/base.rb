module Boxxspring 

  module Worker

    class Base

      #------------------------------------------------------------------------
      # class attributes

      class_attribute :queue_name
      class_attribute :processor

      #------------------------------------------------------------------------
      # class methods

      class << self 

        def process( &block )
          self.processor = block
        end

        def queue
          @queue ||= Aws::SQS::Client.new
        end

        def queue_url
          unless @queue_url.present?
            response = self.queue.create_queue( 
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
        message = self.receive_message
        if message.present?
          payload = payload_from_message( message )
          if payload.present?
            begin
              self.process_payload( payload )
              # note: if an exception is raised the message will not be deleted
              delete_message( message )
              rescue StandardError => error
                raise RuntimeError.new( 
                  "The worker failed to process the payload. #{error.message}."
                )
            end
          else
            # note: messages with invalid payloads are deleted
            delete_message( message )

            raise RuntimeError.new( 
              "The worker received an invalid payload."
            )
          end
          true
        else
          false
        end
      end

      protected; def logger
        @logger ||= Boxxspring::Worker.configuration.logger
      end

      #------------------------------------------------------------------------
      # implementation

      protected; def receive_message
        message = nil
        begin
          response = self.class.queue.receive_message( 
            queue_url: self.class.queue_url 
          )
          messages = response[ :messages ]
          message = messages.first
        rescue StandardError => error
          raise RuntimeError.new( 
            "The worker is unable to receive a message from the queue. #{error.message}."
          )
        end
        message
      end

      protected; def delete_message( message )
        begin
          self.class.queue.delete_message( 
            queue_url: self.class.queue_url,
            receipt_handle: message[ :receipt_handle ]
          )
        rescue StandardError => error
          raise RuntimeError.new( 
            "The worker is unable to delete the message from the queue. #{error.message}."
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

    end

  end

end
