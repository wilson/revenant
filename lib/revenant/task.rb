require 'revenant'

module Revenant
  class Task
    attr_reader :name

    def initialize(name = nil)
      unless String === name || Symbol === name
        raise ArgumentError, "Usage: new(task_name)"
      end
      @name = name.to_sym
    end

    # Takes actual block of code that is to be guarded by
    # the lock.
    # The default +run_loop+ is defined in Revenant::Daemon
    # and the block will execute in a fork.
    def run(&block)
      if block.nil?
        raise ArgumentError, "Usage: run { while_we_have_the_lock }"
      end
      startup # typically daemonizes the process, can have various implementations
      on_load.call if on_load
      run_loop(&block)
    end

    # Code to run when the task is exiting
    def on_exit(&block)
      @on_exit ||= block
    end

    # Code to run just before the task looks for a lock
    # By default, this code runs in a forked process.
    def on_load(&block)
      @on_load ||= block
    end

    # Used to pick the Task's +lock_module+
    # Particular lock types may offer various helpful features
    # via this lock module.
    # Defaults to :mysql
    def lock_type
      @lock_type ||= :mysql
    end

    # Set a new lock type for this Task
    def lock_type=(val)
      @lock_type = val.to_sym
    end

    # Set your own lock function. Will be called with a lock name as the arg.
    # Should return true if a lock has been acquired, false otherwise.
    # task.lock_function {|name| # .. }
    def lock_function(&block)
      if block_given?
        @lock_function = block
      else
        @lock_function ||= lock_module.lock_function
      end
    end

    # Returns a module that knows how to do some distributed locking.
    def lock_module
      ::Revenant.find_module(lock_type)
    end

    # How many work loops to perform before re-acquiring the lock.
    # Defaults to 5.
    # Setting it to 0 or nil will assume the lock is forever valid after
    # acquisition.
    def relock_every
      @relock_every ||= 5
    end

    # Set the frequency with which locks are re-acquired.
    def relock_every=(loops)
      loops ||= 0
      if Integer === loops && loops >= 0
        @relock_every = loops
      else
        raise ArgumentError, "argument must be nil or an integer >= 0"
      end
    end

    # How many seconds to sleep after each work loop.
    # When we don't have the lock, how long to sleep before checking again.
    # Default is 5 seconds.
    def sleep_for
      @sleep_for ||= 5
    end

    # Set the number of seconds to sleep for after a work loop.
    def sleep_for=(seconds)
      seconds ||= 0
      if Integer === seconds && seconds >= 0
        @sleep_for = seconds
      else
        raise ArgumentError, "argument must be nil or an integer >= 0"
      end
    end

    # Run until we receive a shutdown/reload signal,
    # or when the worker raises an Interrupt.
    # Runs after a fork when Revenant::Daemon is enabled.
    def run_loop(&block)
      acquired = false
      loop do
        shutdown if shutdown_pending?

        # The usual situation
        if relock_every != 0
          i ||= 0
          # 0 % anything is 0, so we always try to get the lock on the first loop.
          if (i %= relock_every) == 0
            acquired = lock_function.call(@name)
          end
        else
          # With relock_every set to 0, only acquire the lock once.
          # Hope you're sure that lock beongs to you.
          acquired ||= lock_function.call(@name)
          i = 0 # no point in incrementing something we don't check.
        end

        yield if acquired

        # Sleep one second at a time so we can quickly respond to
        # shutdown requests.
        sleep_for.times do
          sleep(1) unless shutdown_pending?
        end
        i += 1
      end # loop
    rescue Interrupt => ex
      log "shutting down after interrupt: #{ex.message}"
      shutdown
    rescue Exception => ex
      if SystemExit === ex
        raise ex
      else
        error ex.message, false
        shutdown
      end
    ensure
      on_exit.call if on_exit
    end # run_loop
    protected :run_loop

    # This could be the moment.
    def shutdown_pending?
      @shutdown ||= false
    end

    # At last, back to war.
    def restart_pending?
      @restart ||= false
    end

    # Task will restart at the earliest safe opportunity after
    # +restart_soon+ is called.
    def restart_soon
      @restart = true
      @shutdown = true
    end

    # Task will shut down at the earliest safe opportunity after
    # +shutdown_soon+ is called.
    def shutdown_soon
      @restart = false
      @shutdown = true
    end

    # Generally overridden when Revenant::Daemon is included
    def startup
      trap("INT") do
        @shutdown = true
        @restart = false
      end
    end

    ## Generally overridden when Revenant::Daemon is included
    def shutdown
      log "#{name} is shutting down"
      exit 0
    end

    def log(message)
      STDERR.puts "[#{$$}] #{Time.now.iso8601(2)} - #{message}"
    end

    def error(message, quit = true)
      STDERR.puts "[#{$$}] #{Time.now.iso8601(2)} - ERROR: #{message}"
      exit 1 if quit
    end
  end # Task
end # Revenant

