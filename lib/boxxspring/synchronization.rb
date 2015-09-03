#
# module. Synchronization
#
# The synchornization module implements lock/unlock and key/value read/write 
# operations accross multiple instances of the application.

module Boxxspring
  module Synchronization

    def self.configuration( &block )
      configuration = Synchronization::Configuration.instance
      configuration.instance_eval( &block ) unless block.nil?
      configuration
    end

  end
end
