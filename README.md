Boxxspring Worker SDK
=====================

The Boxxspring workers gem provides the base functionality for other Boxxspring workers, such as Youtube Workers, Feed Workers, Subscription Workers, etc.

### Worker base
- The worker has a queue that is subscribed a topic ([Amazon SQS](https://console.aws.amazon.com/sqs/home?region=us-east-1#)). Usually there's only one topic for each environemnt, e.g. `staging-tasks`.
```ruby
# lib/boxxspring/worker/base.rb
@queue_interface ||= Aws::SQS::Client.new
```

- As it receives messages from the topic, it proccesses the payload from the message:
```ruby
self.receive_messages()
payload = self.payload_from_message( message )
self.process_payload( payload )
```

- If there's an error with the payload, the worker will log the error:
```ruby
rescue StandardError => error
  self.logger.error(
    "The #{ self.human_name } worker failed to process the payload."
  )
  self.logger.error( error.message )
  self.logger.info( error.backtrace.join( "\n" ) ) if debug_mode?
```

- Messages are deleted if the payload is invalid or not meant for it `self.delete_message( message )`

- The worker can `delegate_payload` by forwarding a message to another queue

### Task Base
- When the worker receives a payload `process_payload( payload )`, it attempts to read the task, and throws an error if the task can't be retrieved or if there's a SignalException.

- If the task is valid, it is delegated to `process_task( task )`, which is defined in each individual worker.

- The default task_state for a task received by the worker is `idle`.

- The methods beloeve are available to workers inheriting from `Boxxspring::Worker::TaskBase`:
+ `task_write(task)`: Updates the task in the database with new values assigned to task attributes & returns the task.

+ `task_write_state(task, state, message)`: Updates the task state and message with the arguments and returns the updated task.

+ `operation(endpoint)` is a short hand Boxxspring::Operation. Example:
```ruby
Boxxspring::Operation.new(
  "/properties/#{property_id}/tasks/#{task_id}",
  Worker.configuration.api_credentials.to_hash
)
```

### Environment variables
- `REMOTE_LOGGER_PORT`: Specify this for Papertrail to distinguish between development and production logs. Previously the port was written in Boxxspring Workers initialization in each app.
- `LOG_LEVEL`: When set to `debug`, the worker will log messages that are restricted to debug mode.
