module Boxxspring
  module Worker

    class AuthorizationError < Error
        def initialize( message = nil )
            super(
                "Error: The worker is not authorized to perform one or more operations."
            )
        end
     end

     module Authorization
        def authorized( &block )

          begin
            block.call( token )
          rescue AuthorizationError => exception
            retries -= 1

            if retries > 0
              token!
              retry
            else
                raise exception
            end
          end
        end

        private; def token
          @authorization_token ||= begin
             Unimatrix::Authorization::ClientCredentialsGrant.new(
               client_id:     ENV[ 'KEYMAKER_CLIENT' ],
               client_secret: ENV[ 'KEYMAKER_SECRET' ]
             ).request_token
          end
        end

        private; def token!
          @authorization_token = nil
          token
        end

    end
  end
end
