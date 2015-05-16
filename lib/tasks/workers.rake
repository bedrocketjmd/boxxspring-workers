namespace :worker do

  descendants = Boxxspring::Worker::Base.descendants

  # remove base class workers
  descendants.delete( Boxxspring::Worker::TaskBase )

  descendants.each do | worker_class |

    worker_name = worker_class.
                    name.
                    underscore.
                    gsub( /[\/]/, '-' ). 
                    gsub( /_worker\Z/, '' )

    desc "#{worker_name.humanize.downcase} worker."
    task worker_name.to_sym do
      spinner = %w{| / - \\}
      worker = worker_class.new
      print 'working...  ' 
      Boxxspring::Worker.configuration.logger.info(
        "The #{worker_name.humanize.downcase} worker has started." 
      )
      begin
        loop do 
          print "\b" + spinner.rotate!.first
          worker.process
        end
      rescue SystemExit, Interrupt
        Boxxspring::Worker.configuration.logger.info(
          "The #{worker_name.humanize.downcase} worker has stopped." 
        )
        puts 'stopped'
        exit 130
      end 
    end
  end
end