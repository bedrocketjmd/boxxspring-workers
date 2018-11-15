module Boxxspring
  module Worker
    module Authorization

      def authorize( &block )
        begin
          retries ||= 3
          block.call( token )
        rescue Unimatrix::AuthorizationError => exception
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

        if authorization_error?( result )
          raise Unimatrix::AuthorizationError, error_message
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

      protected; def authorization_error?( result )
        result.is_a?( Array ) && 
        ( result.first.is_a?( Unimatrix::ForbiddenError ) || 
          result.first.is_a?( Unimatrix::MissingPolicyError ) )
      end
        
    end
  end
end
