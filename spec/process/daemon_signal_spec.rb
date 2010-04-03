require 'spec_helper'

describe Revenant::Daemon do
  before do
    @task = Revenant::Task.new("daemonsignal")
    @task.stubs(:exit)
  end

  it "is registered as the :daemon plugin" do
    Revenant.plugins[:daemon].should == ::Revenant::Daemon
  end

  it "shuts down on SIGTERM" do
    pending
  end

  it "restarts on SIGUSR2" do
    pending
  end

  it "logs a stack trace on SIGUSR1" do
    pending
  end
end

