require 'revenant/task'
require 'revenant/pid'
require 'daemons'

# "startup" and "shutdown" are the methods Task expects modules like
# this one to replace.
module ::Revenant::Daemon
  def startup
    daemonize
  end

  def shutdown
    @pid.remove

    if restart_pending?
      log "#{name} is restarting"
      system script
    else
      log "#{name} is shutting down"
    end

    exit 0
  end

  # Everything else is a daemon implementation detail, and will not
  # be executed if +Task+ also happens to have a method by the same name.
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
    script # determine script path before forking if necessary
    Daemonize.daemonize(log_file, $0)
    @pid.create
    daemon_signals
  end

  def verify_permissions
    dir = File.dirname(pid_file)
    unless File.directory?(dir) && File.writable?(dir)
      error "pid file is not writeable: #{pid_file.inspect}"
    end

    @pid = ::Revenant::PID.new(pid_file)
    if @pid.exists?
      error "pid file exists: #{pid_file.inspect}. unclean shutdown?"
    end

    return unless log_file

    dir = File.dirname(log_file)
    unless File.directory?(dir) && File.writable?(dir)
      error "log file is not writeable: #{log_file.inspect}"
    end
  end

  def daemon_signals
    trap("TERM") do
      log "Received TERM signal"
      shutdown_soon
    end

    trap("USR2") do
      log "Received USR2 signal"
      restart_soon
    end
  end
end
