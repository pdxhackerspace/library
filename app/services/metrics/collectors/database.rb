require 'sidekiq/api'

module Metrics
  module Collectors
    module Database
      def collect_database
        pool = ActiveRecord::Base.connection_pool.stat
        @out.gauge('library_db_pool_connections', 'Database connection pool state for this process.',
                   pool.slice(:size, :connections, :busy, :idle, :waiting).map { |state, n| [{ state: state }, n] })
        ActiveRecord::Base.with_connection do |conn|
          @out.gauge('library_db_size_bytes', 'Size of the application database.',
                     conn.select_value('SELECT pg_database_size(current_database())').to_i)
        end
      end
    end
  end
end
