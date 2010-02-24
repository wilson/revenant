module Revenant
  class PID
    def initialize(file)
      @file = file
    end

    def exists?
      File.exists?(@file)
    end

    def create
      return false if exists?

      File.open(@file, 'w') do |f|
        f.write(Process.pid)
      end
      true
    end

    def remove
      File.unlink(@file) if exists?
    end
  end
end
