require "spec_helper"

class SmallBatchJob
  extend Resque::Plugins::ScalingCanary
  @queue = 'small-batch-job'

  def self.perform; end
end

class LargeBatchJob
  extend Resque::Plugins::ScalingCanary
  @queue = 'large-batch-job'

  def self.minimum_workers_needed
    20
  end

  def self.perform; end
end

describe Resque::Plugins::ScalingCanary do
  before(:each) do
    @mock_heroku_client = Object.new
    Resque::Plugins::ScalingCanary.config do |config|
      config.heroku_user = "stub-user"
      config.heroku_password = "stub-password"
      config.heroku_app = "stub-app"
      config.polling_interval = 0
      config.stub(:heroku_client) { @mock_heroku_client }
    end
  end

  it "should pass Resque's plugin lint test" do
    lambda { Resque::Plugin.lint(Resque::Plugins::ScalingCanary) }.should_not raise_error
  end
  
  describe "after_enqueue_ensure_heroku_workers" do
    it "should scale workers up to 1 if no :minimum_workers_needed method is implemented" do
      @mock_heroku_client.should_receive(:set_workers).with("stub-app", 1).once
      @mock_heroku_client.should_receive(:set_workers).with("stub-app", 0).once
      @mock_heroku_client.stub(:info) { {:workers => 0} }
      Resque.enqueue SmallBatchJob
    end
    it "should scale workers up to the number specified by :minimum_workers_needed if an implementation is provided" do
      @mock_heroku_client.should_receive(:set_workers).with("stub-app", 20).once
      @mock_heroku_client.should_receive(:set_workers).with("stub-app", 0).once
      @mock_heroku_client.stub(:info) { {:workers => 0} }
      Resque.enqueue LargeBatchJob
    end
    it "should not scale workers at all if scaling is disabled" do
      Resque::Plugins::ScalingCanary::Config.disable_scaling_if{ true }
      @mock_heroku_client.stub(:set_workers){ raise "Not expecting call to :set_workers because scaling is disabled" }
      @mock_heroku_client.stub(:info) { {:workers => 0} }
      Resque.enqueue LargeBatchJob
    end
  end
  
end
