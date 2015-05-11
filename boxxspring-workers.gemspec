# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path( "../lib", __FILE__ )
require 'boxxspring/version'

Gem::Specification.new do | gem |

  gem.version         = Boxxspring::Worker::VERSION
  gem.license         = 'MS-RL'

  gem.name            = 'boxxspring-workers'
  gem.summary         = "Bedrocket Media Ventrures Boxxspring Worker framework."
  gem.description     = "The boxxspring workers gem is implements the framework used to construct boxxspring workers."

  gem.homepage        = "http://bedrocket.com"
  gem.authors         = [ "Kristoph Cichocki-Romanov" ]
  gem.email           = "kristoph@bedrocket.com"

  gem.require_paths  = [ 'lib' ]
  gem.files          = Dir.glob( "{lib}/**/*" )

  gem.add_runtime_dependency( "aws-sdk", "~> 2" )
  gem.add_runtime_dependency( "boxxspring", "~> 2" )
  gem.add_runtime_dependency( "remote_syslog_logger", "~> 1.0" )

  gem.add_development_dependency( "pry", "~> 0.10" )
  gem.add_development_dependency( "pry-byebug", "~> 3.1" )

end

