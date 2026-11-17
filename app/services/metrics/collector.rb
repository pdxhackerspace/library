require 'sidekiq/api'

module Metrics
  # Gathers every metric family and renders them as Prometheus text.
  #
  # Each section (see Metrics::Collectors) runs on its own: if Redis or the
  # database is unreachable the other sections still report, and the failure
  # shows up as library_scrape_collector_success{collector="..."} 0.
  class Collector
    include Collectors::Application
    include Collectors::Database
    include Collectors::SidekiqStats
    include Collectors::Jobs
    include Collectors::Requests

    SECTIONS = %i[application database sidekiq jobs requests].freeze
    BOOT_TIME = Time.now.to_f

    def initialize(exposition: Exposition.new)
      @out = exposition
    end

    def call
      statuses = SECTIONS.map { |section| run_section(section) }
      report_scrape(statuses)
      @out.to_s
    end

    private

    def run_section(section)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      send(:"collect_#{section}")
      [section, true, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]
    rescue StandardError => e
      Rails.logger.error("[metrics] #{section} collector failed: #{e.class}: #{e.message}")
      [section, false, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]
    end

    def report_scrape(statuses)
      @out.gauge('library_scrape_collector_success', '1 if the collector ran without error.',
                 statuses.map { |name, ok, _| [{ collector: name }, ok ? 1 : 0] })
      @out.gauge('library_scrape_collector_duration_seconds', 'Time each collector took.',
                 statuses.map { |name, _, secs| [{ collector: name }, secs.round(6)] })
    end

    def histogram_data(entry, count)
      { buckets: entry[:buckets], sum: entry[:sum], count: count }
    end
  end
end
