module Metrics
  # Shared settings and Redis access for the metrics subsystem.
  #
  # Job and request measurements are accumulated in Redis hashes so that every
  # Puma worker and Sidekiq process contributes to one set of counters, and a
  # scrape of any web process sees all of them.
  module Store
    DEFAULT_PREFIX = 'library:metrics'.freeze
    DURATION_BUCKETS = [0.005, 0.025, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0, 30.0, 60.0, 300.0].freeze

    class << self
      attr_writer :prefix

      def prefix
        @prefix || DEFAULT_PREFIX
      end

      def token
        ENV['METRICS_TOKEN'].presence
      end

      # The endpoint, and all recording, stay off until a token is configured.
      def enabled?
        token.present?
      end

      def key(name)
        "#{prefix}:#{name}"
      end

      def redis(&)
        Sidekiq.redis(&)
      end

      # Name of the first bucket a duration (seconds) falls into, nil for overflow (+Inf).
      def bucket_for(seconds)
        DURATION_BUCKETS.find { |bound| seconds <= bound }
      end

      def reset!
        redis do |conn|
          conn.call('DEL', key('jobs'), key('job_last'), key('requests'))
        end
      end
    end
  end
end
