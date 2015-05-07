require 'aws-sdk'
require 'active_support/all'

$LOAD_PATH.unshift( File.expand_path( '..', File.dirname( __FILE__ ) ) )
require 'lib/boxxspring/abstract'
require 'lib/boxxspring/journal'
require 'lib/boxxspring/worker/configuration'
require 'lib/boxxspring/worker/base'
require 'lib/boxxspring/worker/task_base'