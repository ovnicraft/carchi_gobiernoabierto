module ActiveRecord
  module Tasks #nodoc
    class PostgreSQLDatabaseTasks #nodoc
      def create(master_established = false)
        establish_master_connection unless master_established
        connection.create_database configuration['database'], configuration.merge('encoding' => encoding)
        # Load plpgsql and tildes function
        system "createlang plpgsql #{configuration['database']}"
        system "psql -f #{Rails.root}/db/tildes.sql #{configuration['database']}"
        establish_connection configuration
      rescue ActiveRecord::StatementInvalid => error
        if /database .* already exists/ === error.message
          raise DatabaseAlreadyExists
        else
          raise
        end
      end
    end
  end
end
