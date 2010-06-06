require 'revenant/task'
require 'revenant/pid'
require 'revenant/manager'

# "startup" and "shutdown" are the methods Task expects modules like
# this one to replace.
module ::Revenant::Daemon
  # Installs this plugin in the given +task+.
  # Out of the box, this is always to provide daemon support.
  # +install+ is expected to know when to do nothing.
  def self.install(task)
    if task.daemon?
      class << task
        include ::Revenant::Daemon
      end
    end
  end

  def startup
    @original_dir = ::Revenant.working_directory
    daemonize
    log "#{name} is starting"
  end

  def shutdown
    @pid.remove

    if restart_pending?
      log "#{name} is restarting"
      if @original_dir
        Dir.chdir @original_dir
      end
      system script
    else
      log "#{name} is shutting down"
    end

    exit 0
  end

  ##
  ## Everything else is a daemon implementation detail.
  ##

  def pid_file
    @options[:pid_file] ||= File.join("/tmp", "#{@name}.pid")
  end

  def log_file
    @options[:log_file]
  end

  def script
    @options[:script] ||= File.expand_path($0)
  end

  protected

  def daemonize
    verify_permissions
    ::Revenant::Manager.daemonize(name, log_file)
    @pid.create
    daemon_signals
  end

  def verify_permissions
    unless File.executable?(script)
      error "script file is not executable: #{script.inspect}"
      exit 1
    end

    dir = File.dirname(pid_file)
    unless File.directory?(dir) && File.writable?(dir)
      error "pid file is not writeable: #{pid_file.inspect}"
      exit 1
    end

    @pid = ::Revenant::PID.new(pid_file)
    if @pid.exists?
      error "pid file exists: #{pid_file.inspect}. unclean shutdown?"
      exit 1
    end

    if log_file && dir = File.dirname(log_file)
      unless File.directory?(dir) && File.writable?(dir)
        error "log file is not writeable: #{log_file.inspect}"
        exit 1
      end
    end
  end

  def daemon_signals
    trap("TERM") do
      log "Received TERM signal"
      shutdown_soon
    end

    trap("QUIT") do
      log "QUIT: #{caller.inspect}"
      shutdown_soon
    end

    trap("USR1") do
      log "TRACE: #{caller.inspect}"
    end

    trap("USR2") do
      log "Received USR2 signal"
      restart_soon
    end
  end
end

# Register this plugin
::Revenant.plugins[:daemon] = ::Revenant::Daemon
