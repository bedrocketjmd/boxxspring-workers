module Boxxspring

  module Worker

     module Authorization

        def authorize( &block )
          begin
            retries ||= 3
            block.call( token )
          rescue AuthorizationError => exception
            if ( retries -= 1 ) > 0
              token!
              retry
            else
              raise exception
            end
          end
        end

        def authorize_operation( result = nil, error_message = nil )
          result = yield if block_given?

          if result.is_a?( Array ) && result.first.is_a?( Unimatrix::ForbiddenError )
            raise AuthorizationError, error_message
          end

          result
        end

        protected; def token
          @authorization_token ||= begin
             Unimatrix::Authorization::ClientCredentialsGrant.new(
               client_id:     ENV[ 'KEYMAKER_CLIENT' ],
               client_secret: ENV[ 'KEYMAKER_SECRET' ]
             ).request_token
          end
        end

        protected; def token!
          @authorization_token = nil
          token
        end

    end

    class AuthorizationError < StandardError

      def initialize( message = nil )
        if message.nil?
          message = "Error: The worker is not authorized to perform one " +
            "or more operations."
        end

        super( message )
      end

    end

  end

end
