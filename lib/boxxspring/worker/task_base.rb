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
            "The #{self.human_name} worker lacks a task processor"
          )
        end
      end

      #------------------------------------------------------------------------
      # implementation

      protected; def process_payload( payload )
        result = false
        type_names = self.task_type_name.blank? ? 
          nil : 
          [ self.task_type_name ].flatten
        states = self.task_state.blank? ?
          nil :
          [ self.task_state ].flatten

        tasks = payload[ 'tasks' ]
        if ( tasks.present? && tasks.respond_to?( :each ) ) 
          tasks.each do | task |
            if ( type_names.blank? || type_names.include?( task[ 'type_name'] ) )
              task = task_read( task[ 'property_id' ], task[ 'id' ] )
              if task.is_a?( Boxxspring::Task )
                if ( states.blank? || states.include?( task.state ) )
                  self.logger.info(  
                    "The task (id: #{task.id}) processing has started."
                  )
                  result = self.process_task( task )
                  self.logger.info(  
                    "The task (id: #{task.id}) processing has ended."
                  )
                end
              elsif task.is_a?( Boxxspring::Error )
                # TODO: handle error
                self.logger.info(  
                  "The #{self.human_name} is unable to find the task with " + 
                  "the id."
                )
              else
                # TODO: handle unexpected condition
              end
            end
          end
        end
        result
      end

      protected; def task_read( property_id, task_id )
        # why did this not work?
        # self.task_operation( property_id ).where( id: task_id ).read
        Boxxspring::Operation.new( 
          "/properties/#{property_id}/tasks/#{task_id}",
          Worker.configuration.api_credentials.to_hash
        ).read      
      end

      protected; def task_write( task )
        self.task_operation( task.property_id ).write( 'tasks', task ).first
      end

      protected; def task_write_state( task, state, message )
        self.logger.info( message ) unless message.blank?
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
        operation = operation.include( include ) unless ( include.blank? ) 
        operation.read
      end

    end

  end

end