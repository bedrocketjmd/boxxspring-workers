module Boxxspring
  module Synchronization

    def self.configuration( &block )
      configuration = Synchronization::Configuration.instance
      configuration.instance_eval( &block ) unless block.nil?
      configuration
    end

  end
end
