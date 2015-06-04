require_relative "wiki.rb"

use Rack::MethodOverride

run Wiki::Server