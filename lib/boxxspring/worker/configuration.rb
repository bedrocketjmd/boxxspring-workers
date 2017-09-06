require 'singleton'

module Boxxspring

  module Worker

    class Configuration < Abstract

      include Singleton

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