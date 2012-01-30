require "spec_helper"

describe Resque::Plugins::ScalingCanary::Config do
  describe "scaling_disabled?" do
    it "returns false by default" do
      subject.scaling_disabled?.should be_false
    end
    it "returns the results of a call to disable_scaling_if when an implementation is provided" do
      subject.disable_scaling_if{ true }
      subject.scaling_disabled?.should be_true
      subject.disable_scaling_if{ false }
      subject.scaling_disabled?.should be_false
    end
  end
end
