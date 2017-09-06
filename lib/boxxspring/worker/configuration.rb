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
          env: ENV[ 'WORKERS_ENV' ] || 'development'
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

    end

  end

end