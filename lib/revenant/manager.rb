module Revenant
  module Manager
    extend self

    def daemonize(name, log_file = nil)
      # Firstly, get rid of the filthy dirty original process.
      exit! if fork

      # Now that we aren't attached to a terminal, we can become
      # a session leader.
      begin
        Process.setsid
      rescue Errno::EPERM
        raise SystemCallError, "setsid failed. terminal failed to detach?"
      end
      trap 'SIGHUP', 'IGNORE' # don't do anything crazy when this process exits

      # Finally, time to create a daemonized process
      exit!(0) if fork

      $0 = name.to_s # set the process name
      close_open_files
      redirect_io_to(log_file)
      srand # re-seed the PRNG with our 'final' pid
    end

    # Close anything that is not one of the three standard IO streams.
    def close_open_files
      ObjectSpace.each_object(IO) do |io|
        next if [STDIN, STDOUT, STDERR].include?(io)
        begin
          io.close unless io.closed?
        rescue ::Exception
        end
      end
    end

    # Redirects STDIN, STDOUT, and STDERR to the specified +log_file+
    # or to /dev/null if none is given.
    def redirect_io_to(log_file)
      log_file ||= "/dev/null"
      reopen_io STDIN, "/dev/null"
      reopen_io STDOUT, log_file, "a"
      reopen_io STDERR, STDOUT
      STDERR.sync = STDOUT.sync = true
    end

    # Attempts to reopen an IO object.
    def reopen_io(io, path, mode = nil)
      begin
        if mode
          io.reopen(path, mode)
        else
          io.reopen(path)
        end
        io.binmode
      rescue ::Exception
      end
    end
  end
end

