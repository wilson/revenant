require 'revenant'
require 'time'

module Revenant
  class Task
    attr_reader :name
    attr_accessor :options
    attr_writer :logger

    def initialize(name = nil)
      unless String === name || Symbol === name
        raise ArgumentError, "Usage: new(task_name)"
      end
      @name = name.to_sym
      @options = {}
    end

    # Generally overridden when Revenant::Daemon is included
    def startup
      trap("INT") { shutdown_soon }
    end

    ## Generally overridden when Revenant::Daemon is included
    # The stack gets deeper here on every restart; this is here
    # largely to ease testing.
    # Implement your own plugin providing +shutdown+ if you want to
    # make something serious that calls this code after a
    # restart signal.
    def shutdown
      if restart_pending? && @work
        log "#{name} is restarting"
        run(&@work)
      else
        log "#{name} is shutting down"
      end
    end

    # Takes actual block of code that is to be guarded by
    # the lock. The +run_loop+ method does the actual work.
    #
    # If 'daemon?' is true, your code (including +on_load+)
    # will execute after a fork.
    #
    # Make sure you don't open files and sockets in the exiting
    # parent process by mistake. Open them in code that is called
    # via +on_load+.
    def run(&block)
      unless @work = block
        raise ArgumentError, "Usage: run { while_we_have_the_lock }"
      end
      @shutdown = false
      @restart = false
      install_plugins
      startup # typically daemonizes the process, can have various implementations
      on_load.call(self) if on_load
      run_loop(&@work)
      on_exit.call(self) if on_exit
      shutdown
    end

    # Code to run just before the task looks for a lock
    # This code runs after any necessary forks, and is
    # therefore the proper place to open databases, logfiles,
    # and any other resources you require.
    def on_load(&block)
      @on_load ||= block
    end

    # Code to run when the task is exiting.
    def on_exit(&block)
      @on_exit ||= block
    end

    # Used to pick the Task's +lock_module+
    # Particular lock types may offer various helpful features
    # via this lock module.
    # Defaults to :mysql
    def lock_type
      @lock_type ||= :mysql
    end

    # Set a new lock type for this Task.
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
    # May not be the code that actually performs the lock, if this
    # Task has had a +lock_function+ assigned to it explicitly.
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
    # Setting it to 0 or nil will assume the lock is forever valid after
    # acquisition.
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

    ## Used to lazily store/retrieve options that may be needed by plugins.
    # We may want to capture, say, +log_file+ before actually loading the
    # code that might care about such a concept.
    def method_missing(name, *args)
      name = name.to_s
      last_char = name[-1,1]
      super(name, *args) unless last_char == "=" || last_char == "?"
      attr_name = name[0..-2].to_sym # :foo for 'foo=' or 'foo?'
      if last_char == "="
        @options[attr_name] = args.at(0)
      else
        @options[attr_name]
      end
    end

    def log(message)
      logger.puts "[#{$$}] #{Time.now.iso8601(2)} - #{message}"
    end

    def error(message)
      logger.puts "[#{$$}] #{Time.now.iso8601(2)} - ERROR: #{message}"
    end

    def logger
      @logger ||= STDERR
    end

    # Install any plugins that have registered themselves, or a custom
    # list if the user has set it themselves.
    def install_plugins
      ::Revenant.plugins.each do |name, plugin|
        plugin.install(self)
      end
    end

    # Run until we receive a shutdown/reload signal,
    # or when the worker raises an Interrupt.
    # Runs after a fork when Revenant::Daemon is enabled.
    def run_loop(&block)
      acquired = false
      begin
        until shutdown_pending?
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
        shutdown_soon # Always shut down from an Interrupt, even mid-restart.
      rescue Exception => ex
        error "restarting after error: #{ex.message}"
        restart_soon # Restart if we run into an exception.
      end # begin block
    end # run_loop
  end # Task
end # Revenant

