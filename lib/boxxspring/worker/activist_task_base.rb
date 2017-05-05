module Boxxspring

  module Worker

    class ActivistTaskBase < Base

      #------------------------------------------------------------------------
      # class attributes

      class_attribute :task_type_name
      class_attribute :task_state

      #------------------------------------------------------------------------
      # operations

      protected; def process_task( task )
        if self.class.processor.present? 
          self.class.processor.call( task )
        else
          raise RuntimeError.new( 
            "The #{ self.human_name } lacks a task processor"
          )
        end
      end

      #------------------------------------------------------------------------
      # implementation

      protected; def process_payload( payload )
        result = true
        type_names = self.task_type_name.blank? ? 
                       nil : [ self.task_type_name ].flatten
        states = self.task_state.blank? ?
                   nil : [ self.task_state ].flatten
        tasks = payload[ 'tasks' ]

        if tasks.present? && tasks.respond_to?( :each )
          tasks.each do | task |
            task_id = task[ 'id' ]
            if type_names.blank? || type_names.include?( task[ 'type_name' ] )
              task = task_read( task[ 'property_id' ], task_id )

              if task.is_a?( Boxxspring::Task )
                if states.blank? || states.include?( task.state )
                  self.logger.info(  
                    "Task #{ task.id } processing has started."
                  )
                  begin
                    result = self.process_task( task )
                    message = "Task #{ task.id } processing has ended"
                    message += " and the message was retained." if result == false
                    self.logger.info( message )
                  rescue SignalException, StandardError => error
                    if error.is_a?( SignalException )
                      task_state = 'idle'
                      task_message = "Task #{ task.id } has restarted."
                    else
                      task_state = 'failed'
                      task_message = "Task #{ task.id } processing has failed."
                    end
                    task = task_write_state( task, task_state, task_message )
                    self.logger.error( error.message )
                    self.logger.info( error.backtrace.join( "\n" ) )
                    raise error if error.is_a?( SignalException )
                  end
                end
              elsif task.is_a?( Array ) && task.first.respond_to?( :message )
                self.logger.error( task.first.message )
              else
                self.logger.error(
                  "The #{self.human_name} is unable to retrieve the " +
                  "task with the id #{task_id}. #{task.inspect}"
                )
              end
            end
          end
        end

        result
      end

      protected; def task_read( realm_uuid, task_id )
        # why did this not work?
        # self.task_operation( property_id ).where( id: task_id ).read
        Unimatrix::Activist::Operation.new( 
          "/realms/#{ realm_uuid }/tasks/#{ task_id }",
          Worker.configuration.api_credentials.to_hash
        ).read      
      end

      protected; def task_write( task )
        self.task_operation( task.realm_uuid ).write( 'tasks', task ).first
      end

      protected; def task_write_state( task, state, message )
        self.logger.send( ( state == 'failed' ? 'error' : 'info' ), message ) \
          unless message.blank?
        task.state = state
        task.message = message
        self.task_write( task )
      end

      protected; def task_operation( realm_uuid )
        Unimatrix::Activist::Operation.new( 
          "/realms/#{ realm_uuid }/tasks",
          Worker.configuration.api_credentials.to_hash
        )
      end

      # protected; def task_property_read( task, include = nil )
      #   operation = Boxxspring::Operation.new( 
      #     "/properties/#{ task.property_id }", 
      #     Worker.configuration.api_credentials.to_hash
      #   )
      #   operation = operation.include( include ) \
      #     unless ( include.blank? ) 
      #   operation.read
      # end

      protected; def task_delegate( queue_name, task )
        serializer = Unimatrix::Activist::Serializer.new( task )
        payload = serializer.serialize( 'tasks' )
        payload.merge!( { 
          '$this' => { 
            'type_name' => 'tasks', 
            'unlimited_count' => 1
          }
        } )
        self.delegate_payload( queue_name, payload )
      end

    end

  end

end
