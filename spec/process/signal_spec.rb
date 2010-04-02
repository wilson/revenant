require 'spec_helper'
require 'revenant/task'

describe Revenant::Task do
  before do
    @task = Revenant::Task.new("signalspec")
  end

  it "shuts down on SIGINT when in the foreground" do
    pending
    @task.should_not be_shutdown_pending
    @task.should_not be_restart_pending
  end
end

