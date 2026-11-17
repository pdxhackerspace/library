module Metrics
  # Records controller actions (count by status, duration histogram, DB and
  # view time) from ActiveSupport::Notifications. The metrics endpoint itself
  # is excluded.
  module RequestRecorder
    IGNORED_CONTROLLERS = %w[MetricsController].freeze

    module_function

    def subscribe!
      ActiveSupport::Notifications.subscribe('process_action.action_controller') do |event|
        record(event.payload, event.duration / 1000.0)
      end
    end

    def record(payload, seconds)
      return unless Store.enabled?

      controller = payload[:controller].to_s
      return if IGNORED_CONTROLLERS.include?(controller)

      write(controller, payload[:action].to_s, status_for(payload), seconds, payload)
    rescue StandardError => e
      Rails.logger.warn("[metrics] could not record request: #{e.class}: #{e.message}")
    end

    def write(controller, action, status, seconds, payload)
      route = "#{controller}|#{action}"
      Store.redis do |conn|
        conn.pipelined do |pipe|
          pipe.call('HINCRBY', Store.key('requests'), "#{route}|status:#{status}", 1)
          pipe.call('HINCRBYFLOAT', Store.key('requests'), "#{route}|sum", seconds)
          pipe.call('HINCRBY', Store.key('requests'), "#{route}|le:#{Store.bucket_for(seconds) || '+Inf'}", 1)
          pipe.call('HINCRBYFLOAT', Store.key('requests'), "#{route}|db", (payload[:db_runtime] || 0) / 1000.0)
          pipe.call('HINCRBYFLOAT', Store.key('requests'), "#{route}|view", (payload[:view_runtime] || 0) / 1000.0)
        end
      end
    end

    def status_for(payload)
      payload[:status] || (payload[:exception] ? 500 : 0)
    end

    # => [{ controller:, action:, statuses: {code => n}, sum:, db:, view:, buckets: }]
    def read
      raw = Store.redis { |conn| conn.call('HGETALL', Store.key('requests')) }
      raw = raw.each_slice(2).to_h if raw.is_a?(Array)

      raw.each_with_object({}) do |(field, value), routes|
        controller, action, kind = field.split('|', 3)
        entry = (routes[[controller, action]] ||=
                   { controller: controller, action: action, statuses: {}, sum: 0.0, db: 0.0, view: 0.0,
                     buckets: {} })
        add_field(entry, kind, value)
      end.values
    end

    def add_field(entry, kind, value)
      case kind
      when /\Astatus:(.+)\z/ then entry[:statuses][Regexp.last_match(1)] = value.to_i
      when 'sum', 'db', 'view' then entry[kind.to_sym] = value.to_f
      when /\Ale:(.+)\z/
        bound = Regexp.last_match(1)
        entry[:buckets][bound == '+Inf' ? :inf : bound.to_f] = value.to_i
      end
    end
    private_class_method :add_field
  end
end
