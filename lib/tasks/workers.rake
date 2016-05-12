require 'boxxspring-worker'

namespace :worker do

  descendants = Boxxspring::Worker::Base.descendants
  descendants.delete( Boxxspring::Worker::TaskBase )

  descendants.each do | worker_class |
    worker_name = worker_class.name.underscore.gsub(/_worker\Z/, '')
    human_name  = worker_class.name.underscore.gsub('_', ' ')
    logger      = Boxxspring::Worker.configuration.logger

    desc "#{human_name}"
    task worker_name.to_sym do
      worker = worker_class.new

      spinner = %w{| / - \\}
      print 'working...  ' 
      logger.info( "The #{human_name} has started." )

      begin
        loop do 
          print "\b" + spinner.rotate!.first
          worker.process
        end
      rescue SystemExit, Interrupt
        logger.info( "The #{human_name} has stopped." )
        puts 'stopped'
        exit 130
      end 
    end
  end

end