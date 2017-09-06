module Boxxspring 

  module Worker

    module Logging

      def logger

        @logger || begin

          logger = Workers.configuration.logger 
          return if logger.present?

          if self.log_local?

            logger = Logger.new( STDOUT )

          else

            workers_env = ENV[ 'WORKERS_ENV' ]
            group_name = self.group_name 
            raise 'A logging group is required' unless group_name.present?

            worker_name = self.human_name.gsub( ' ','_' )

            if workers_env == "development"
              username = ENV[ 'USER' ] || ENV[ 'USERNAME' ]
              username = username.underscore.dasherize

              group_name = "#{ username }.#{ group_name }"
            end

            logger = CloudWatchLogger.new( 
              {
                access_key_id: ENV[ 'AWS_ACCESS_KEY_ID' ],
                secret_access_key: ENV[ 'AWS_SECRET_ACCESS_KEY' ] 
              },
              group_name,
              worker_name 
            )

          end

          logger.level = self.log_level 

          logger
            
        end

      end

      protected; def log_group_name
        group_name = ENV[ 'LOG_GROUP' ]
        group_name ||= begin 
          name = `git config --get remote.origin.url` rescue nil
          name.present? ? File.basename( name, '.*' ) : nil
        end
        group_name
      end

      protected; def log_level 
        level = Logger::WARN
        if ENV[ 'LOG_LEVEL' ].present? 
          level = ENV[ 'LOG_LEVEL' ].upcase
          raise "An unkown log level was specificed by LOG_LEVEL." \
            unless [ "INFO", "WARN", "ERROR", "DEBUG", "FATAL" ].include?( level )
          level = "Logger::#{ level }".constantize
        end 
        level 
      end

      protected; def log_local?
        log_local = ENV[ 'LOG_LOCAL' ] || 'false'
        ( log_local.to_s =~ /^true$/i ) == 0
      end      

    end

  end

end
