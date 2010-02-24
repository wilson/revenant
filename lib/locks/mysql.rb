# Each lock module must implement a singleton method called +lock_function+
# This method should return a proc that will be called with a lock_name argument.
# The proc should return true if the lock has been acquired, false otherwise
#
# Lock modules may expose other methods to users as needed, but only
# +lock_function+ is required.
# Modules register new lock types by calling Revenant.register(name, klass)
module Revenant
  module MySQL
    extend self

    def lock_function
      Proc.new do |lock_name|
        ::Revenant::MySQL.acquire_lock(lock_name)
      end
    end

    # Expects the connection to behave like an instance of +Mysql+
    # If you need something else, replace +acquire_lock+ with your own code.
    # Or define your own lock_function while configuring a new Revenant task.
    def acquire_lock(lock_name)
      begin
        acquired = false
        sql = lock_query(lock_name)
        connection.query(sql) do |result|
          acquired = result.fetch_row.first == "1"
        end
        acquired
      rescue ::Exception
        false
      end
    end

    def lock_query(lock_name)
      "select get_lock('#{lock_name}',0);"
    end

    # Currently defaults to the ActiveRecord connection # if AR is loaded.
    # Set this in your task setup block if that is not what you want.
    def connection
      @connection ||= if defined?(ActiveRecord)
                        ActiveRecord::Base.connection.raw_connection
                      else
                        raise "No connection established or discovered. Use Revenant::MySQL::connection="
                      end
    end

    def connection=(conn)
      @connection = conn
    end
  end

  # This is how you register a new lock_type
  register :mysql, MySQL
end

