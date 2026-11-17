module Metrics
  # Builds Prometheus text exposition format (version 0.0.4).
  class Exposition
    CONTENT_TYPE = 'text/plain; version=0.0.4; charset=utf-8'.freeze

    def initialize
      @lines = []
    end

    def gauge(name, help, samples)
      family(name, help, 'gauge', samples)
    end

    def counter(name, help, samples)
      family(name, help, 'counter', samples)
    end

    # series: { labels_hash => { buckets: { upper_bound => non_cumulative_count }, sum:, count: } }
    def histogram(name, help, series, bounds: Store::DURATION_BUCKETS)
      return if series.empty?

      @lines << "# HELP #{name} #{escape_help(help)}" << "# TYPE #{name} histogram"
      series.each { |labels, data| histogram_series(name, labels, data, bounds) }
    end

    def to_s
      "#{@lines.join("\n")}\n"
    end

    private

    # samples: a number (no labels), or [[labels_hash, value], ...]
    def family(name, help, type, samples)
      samples = [[{}, samples]] unless samples.is_a?(Array)
      return if samples.empty?

      @lines << "# HELP #{name} #{escape_help(help)}" << "# TYPE #{name} #{type}"
      samples.each { |labels, value| @lines << "#{name}#{format_labels(labels)} #{format_value(value)}" }
    end

    def histogram_series(name, labels, data, bounds)
      running = 0
      bounds.each do |bound|
        running += data[:buckets].fetch(bound, 0)
        @lines << "#{name}_bucket#{format_labels(labels.merge(le: format_value(bound)))} #{running}"
      end
      @lines << "#{name}_bucket#{format_labels(labels.merge(le: '+Inf'))} #{data[:count]}"
      @lines << "#{name}_sum#{format_labels(labels)} #{format_value(data[:sum])}"
      @lines << "#{name}_count#{format_labels(labels)} #{data[:count]}"
    end

    def format_labels(labels)
      return '' if labels.blank?

      pairs = labels.map { |key, value| %(#{key}="#{escape_label(value)}") }
      "{#{pairs.join(',')}}"
    end

    def format_value(value)
      case value
      when Float
        if value.nan? then 'NaN'
        elsif value.infinite? then value.positive? ? '+Inf' : '-Inf'
        else value.to_s
        end
      when nil then 'NaN'
      else value.to_s
      end
    end

    def escape_label(value)
      value.to_s.gsub('\\') { '\\\\' }.gsub('"') { '\\"' }.gsub("\n") { '\\n' }
    end

    def escape_help(text)
      text.to_s.gsub('\\') { '\\\\' }.gsub("\n") { '\\n' }
    end
  end
end
