require 'revenant/task'
require 'revenant/pid'
require 'daemons'

# "startup" and "shutdown" are the methods Task expects modules like
# this one to override.
module ::Revenant::Daemon
  def startup
    daemonize
  end

  def shutdown
    @pid.remove

    if rise_again?
      log "#{name} is restarting"
      `#{script}`
    else
      log "#{name} is shutting down"
    end

    exit 0
  end

  def pid_file
    @pid_file ||= File.join("/tmp",@name)
  end

  def pid_file=(val)
    @pid_file = val
  end

  attr_accessor :log_file

  # Everything else is a daemon implementation detail
  protected

  def script
    @script ||= File.expand_path($0)
  end

  def script=(path)
    @script = path
  end

  def daemonize
    verify_permissions
    Daemonize.daemonize(log_file, $0)
    @pid.create
    setup_signals
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

  def setup_signals
    trap("TERM") do
      log "Received TERM signal"
      @shutdown = true
      @restart = false
    end

    trap("USR2") do
      log "Received USR2 signal"
      @shutdown = true
      @restart = true
    end
  end
end

# Teach Tasks how to run like daemons
class ::Revenant::Task
  include ::Revenant::Daemon
end

