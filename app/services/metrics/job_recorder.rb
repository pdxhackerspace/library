module Metrics
  # Records one Sidekiq job execution: counts, duration histogram and last-run
  # timestamps, keyed by job class and queue. Fed by Metrics::SidekiqMiddleware.
  module JobRecorder
    module_function

    def record(job_class, queue, seconds, success:)
      return unless Store.enabled?

      base = "#{job_class}|#{queue}"
      bucket = Store.bucket_for(seconds)
      status = success ? 'success' : 'failure'

      Store.redis do |conn|
        conn.pipelined do |pipe|
          pipe.call('HINCRBY', Store.key('jobs'), "#{base}|#{status}", 1)
          pipe.call('HINCRBYFLOAT', Store.key('jobs'), "#{base}|sum", seconds)
          pipe.call('HINCRBY', Store.key('jobs'), "#{base}|le:#{bucket || '+Inf'}", 1)
          pipe.call('HSET', Store.key('job_last'), "#{job_class}|#{status}", Time.now.to_f)
        end
      end
    rescue StandardError => e
      Rails.logger.warn("[metrics] could not record job #{job_class}: #{e.class}: #{e.message}")
    end

    # => { job:, queue:, success:, failure:, sum:, buckets: } per job class and queue
    def read
      raw = Store.redis { |conn| conn.call('HGETALL', Store.key('jobs')) }
      raw = raw.each_slice(2).to_h if raw.is_a?(Array)

      raw.each_with_object({}) do |(field, value), series|
        job, queue, kind = field.split('|', 3)
        entry = (series[[job, queue]] ||= { job: job, queue: queue, success: 0, failure: 0, sum: 0.0, buckets: {} })
        add_field(entry, kind, value)
      end.values
    end

    def last_runs
      raw = Store.redis { |conn| conn.call('HGETALL', Store.key('job_last')) }
      raw = raw.each_slice(2).to_h if raw.is_a?(Array)
      raw.map do |field, value|
        job, status = field.split('|', 2)
        [job, status, value.to_f]
      end
    end

    def add_field(entry, kind, value)
      case kind
      when 'success', 'failure' then entry[kind.to_sym] = value.to_i
      when 'sum' then entry[:sum] = value.to_f
      when /\Ale:(.+)\z/
        bound = Regexp.last_match(1)
        entry[:buckets][bound == '+Inf' ? :inf : bound.to_f] = value.to_i
      end
    end
    private_class_method :add_field
  end
end
