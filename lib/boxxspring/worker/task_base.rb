module Boxxspring

  module Worker

    class TaskBase < Base

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
        task = payload[ 'tasks' ].first

        task_type_name = self.human_name.split( " " )
        task_type_name.pop
        task_type_name = task_type_name.join( "_" ) + "_task"

        if task.present?
          task_uuid = task[ 'uuid' ]
          if task_type_name == payload[ '$this' ][ 'type_name' ]
            task = Unimatrix::Activist::Task.new( task )

            if task.is_a?( Unimatrix::Activist::Task )
              self.logger.info(
                "Task #{ task.uuid } processing has started."
              )
              begin
                result = self.process_task( task )
                message = "Task #{ task.uuid } processing has ended"
                message += " and the message was retained." if result == false
                self.logger.info( message )
              rescue SignalException, StandardError => error
                if error.is_a?( SignalException )
                  task_state = 'idle'
                  task_message = "Task #{ task.uuid } has restarted."
                else
                  task_state = 'failed'
                  task_message = "Task #{ task.uuid } processing has failed."
                end
                task = task_write_state( task, task_state, task_message )
                self.logger.error( error.message )
                self.logger.info( error.backtrace.join( "\n" ) )
                raise error if error.is_a?( SignalException )
              end
            elsif task.is_a?( Array ) && task.first.respond_to?( :message )
              self.logger.error( task.first.message )
            else
              self.logger.error(
                "The #{self.human_name} is unable to retrieve the " +
                "task with the id #{task.uuid}. #{task.inspect}"
              )
            end
          end
        end

        result
      end

      #REVISE!
      protected; def task_read( property_id, task )
        Boxxspring::Operation.new(
          "/properties/#{ property_id }/tasks/#{ task.uuid }",
          Worker.configuration.api_credentials.to_hash
        ).read
      end

      protected; def task_write( task )
        self.task_operation( task.property_id ).write( 'tasks', task ).first
      end

      protected; def task_write_state( task, state, message )
        self.logger.send( ( state == 'failed' ? 'error' : 'info' ), message ) \
          unless message.blank?
        task.state = state
        task.message = message
        self.task_write( task )
      end

      protected; def task_operation( property_id )
        Boxxspring::Operation.new(
          "/properties/#{ property_id }/tasks",
          Worker.configuration.api_credentials.to_hash
        )
      end

      protected; def task_property_read( task, include = nil )
        operation = Boxxspring::Operation.new(
          "/properties/#{ task.property_id }",
          Worker.configuration.api_credentials.to_hash
        )
        operation = operation.include( include ) \
          unless ( include.blank? )
        operation.read
      end

      protected; def task_delegate( queue_name, task )
        serializer = Boxxspring::Serializer.new( task )
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
