#
# Some patches for postgres adapter to work with postgres 8.1
#
# eli@efaber.net, 17-10-2008

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter

      # The drop_database function uses IF EXISTS which is introduced in Postgres 8.2
      # Here we use postgres 8.1, so we have overriden the drop_database method.
      def drop_database(name) #:nodoc:
        execute "DROP DATABASE #{name}"
      end


      # The newer versions of postgres provides the method transaction_status.
      # original file activerecord-2.2.2/lib/active_record/connection_adapters/postgresql_adapter.rb
      def transaction_active?
        0
      end

    end
  end
end
