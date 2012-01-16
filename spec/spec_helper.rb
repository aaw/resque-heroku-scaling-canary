require 'rspec'
require 'heroku'
require 'resque'
require 'resque/plugins/resque_heroku_scaling_canary/config'
require 'resque/plugins/resque_heroku_scaling_canary'

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
end
