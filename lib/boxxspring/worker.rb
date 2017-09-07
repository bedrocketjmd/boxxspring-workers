module Boxxspring

  module Worker

    def self.configuration( &block )
      Configuration.instance().instance_eval( &block ) unless block.nil?
      Configuration.instance()
    end

    def self.env 
      @environment ||= ENV[ 'WORKERS_ENV' ] || 'development'
    end

    def self.root
      @root ||= begin 
        specification = Gem::Specification.find_by_name( 'boxxspring-workers' ) 
        Pathname.new( specification.gem_dir )
      end
    end

  end

end
