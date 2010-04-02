require 'spec_helper'

describe Revenant::Task do
  before do
    @task = Revenant::Task.new("daemonsignal")
    @task.stubs(:exit)
  end

  it "shuts down on SIGTERM" do
    pending
  end

  it "restarts on SIGUSR2" do
    pending
  end
end

