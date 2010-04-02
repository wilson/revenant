require 'spec_helper'

describe Revenant::Task do
  before do
    @task = Revenant::Task.new("spec")
    module SpecLock
      def self.lock_function
        proc { 5 }
      end
    end
    @lock = SpecLock
    Revenant.register("spec", @lock)
  end

  it "requires a name" do
    lambda do
      task = Revenant::Task.new(nil)
    end.should raise_error(ArgumentError)
  end

  it "has no on_exit block by default" do
    @task.on_exit.should == nil
  end

  it "has no on_load block by default" do
    @task.on_load.should == nil
  end

  it "captures an on_exit block" do
    @task.on_exit { nil }
    @task.on_exit.should be_instance_of(Proc)
  end

  it "captures an on_load block" do
    @task.on_load { true }
    @task.on_load.should be_instance_of(Proc)
  end

  it "has a default lock type" do
    @task.lock_type.should == :mysql
  end

  it "can specify a lock type" do
    @task.lock_type = "spec"
    @task.lock_type.should == :spec
  end

  it "finds the matching lock module" do
    @task.lock_module.should == ::Revenant::MySQL
    @task.lock_type = "spec"
    @task.lock_module.should == @lock
  end

  it "defaults to re-locking every 5 loops" do
    @task.relock_every.should == 5
  end

  it "rejects invalid 'relock_every' settings" do
    lambda do
      @task.relock_every = -1
    end.should raise_error(ArgumentError)
  end

  it "can disable relocking by setting 'relock_every' to 0 or nil" do
    @task.relock_every = nil
    @task.relock_every.should == 0
    @task.relock_every = 0
    @task.relock_every.should == 0
  end

  it "defaults to sleeping for 5 seconds between loops" do
    @task.sleep_for.should == 5
  end

  it "rejects invalid 'sleep_for' settings" do
    lambda do
      @task.sleep_for = -1
    end.should raise_error(ArgumentError)
  end

  it "accepts a 0 'sleep_for' value" do
    @task.sleep_for = 0
    @task.sleep_for.should == 0
  end

  context "#lock_function" do
    it "captures a 'lock_function' block" do
      @task.lock_function do
        true
      end
      @task.lock_function.should be_instance_of(Proc)
      @task.lock_function.should_not == Revenant::MySQL.lock_function
    end

    it "replaces an existing 'lock_function' if it is set" do
      @task.lock_function do
        true
      end
      func = proc { false }
      @task.lock_function(&func)
      @task.lock_function.should == func
    end
  end

  context "logging" do
    before do
      @now = Time.now
      @time = @now.iso8601(2)
      @pid = $$
      Time.stubs(:now).returns(@now)
      STDERR.stubs(:puts)
    end

    it "prepends the time and PID to log messages" do
      expected = "[#{@pid}] #{@time} - hello"
      STDERR.expects(:puts).with(expected)
      @task.log "hello"
    end

    it "prepends the time and PID to error messages" do
      expected = "[#{@pid}] #{@time} - ERROR: bad"
      STDERR.expects(:puts).with(expected)
      @task.error "bad"
    end
  end

  context "#startup" do
    it "traps the INT signal" do
      @task.expects(:trap).with("INT")
      @task.startup
    end
  end

  context "#shutdown" do
    it "logs the event" do
      @task.expects(:log).with("spec is shutting down")
      @task.shutdown
    end
  end

  it "can be restarted" do
    @task.restart_soon
    @task.should be_shutdown_pending
    @task.should be_restart_pending
  end

  it "can be shut down" do
    @task.shutdown_soon
    @task.should be_shutdown_pending
    @task.should_not be_restart_pending
  end

  context "#run" do
    context "without an on_load function" do
    end

    context "with an on_load function" do
    end
  end

  context "#run_loop" do
    context "relock_every = 0" do
    end

    context "relock_every = 1" do
    end

    context "encountering an Interrupt"
    context "encountering a SystemExit"
    context "encountering an Exception"
  end
end
