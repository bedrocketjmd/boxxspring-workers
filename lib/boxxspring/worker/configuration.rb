require 'singleton'

module Boxxspring

  module Worker

    def self.configuration( &block )
      Configuration.instance().instance_eval( &block ) unless block.nil?
      Configuration.instance()
    end

    def self.env 
      self.configuration.env
    end

    class Configuration < Abstract

      include Singleton

      def initialize
        super( { 
          env: ENV[ 'WORKERS_ENV' ] || 'development',
          logger: Logger.new( STDOUT )
        } )  
      end

      def self.reloadable?
        false
      end

      def from_hash( configuration )
        configuration.each_pair do | name, value |
          self.send( "@#{name}", value )
        end
      end

      def get_token( options = {} )

        token_details = Unimatrix::Authorization::ClientCredentialsGrant.new(
          client_id: ENV[ 'KEYMAKER_CLIENT' ],
          client_secret: ENV[ 'KEYMAKER_SECRET' ]
        ).request_token( options )

        if token_details.include?( 'error' )
          puts "ERROR: #{ token_details }"
        end

        if token_details.is_a?( Hash )
          token_details.symbolize_keys!
          token_details.update( expires_in: Time.now + token_details[ :expires_in ] ) if token_details[ :expires_in ]
          api_credentials.access_token =  token_details[ :access_token ]
          api_credentials.token_expiry =  token_details[ :expires_in ]
          result = api_credentials
        else
          result = token_details
        end
        result
      end
    end
  end

end