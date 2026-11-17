require 'sidekiq/api'

module Metrics
  module Collectors
    module SidekiqStats
      SET_SCAN_LIMIT = 1000

      def collect_sidekiq
        stats = Sidekiq::Stats.new
        collect_sidekiq_totals(stats)
        collect_sidekiq_queues
        collect_sidekiq_processes
        collect_sidekiq_sets
        collect_sidekiq_cron
      end

      def collect_sidekiq_totals(stats)
        @out.counter('library_sidekiq_processed_total', 'Jobs processed since stats were last reset.', stats.processed)
        @out.counter('library_sidekiq_failed_total', 'Job executions that raised.', stats.failed)
        @out.gauge('library_sidekiq_enqueued', 'Jobs waiting in queues.', stats.enqueued)
        @out.gauge('library_sidekiq_scheduled', 'Jobs scheduled for later.', stats.scheduled_size)
        @out.gauge('library_sidekiq_retries', 'Jobs waiting to be retried.', stats.retry_size)
        @out.gauge('library_sidekiq_dead', 'Jobs in the dead set.', stats.dead_size)
        @out.gauge('library_sidekiq_busy', 'Jobs running right now.', stats.workers_size)
      end

      def collect_sidekiq_queues
        queues = Sidekiq::Queue.all
        @out.gauge('library_sidekiq_queue_size', 'Jobs in each queue.', queues.map { |q| [{ queue: q.name }, q.size] })
        @out.gauge('library_sidekiq_queue_latency_seconds', 'Age of the oldest job in each queue.',
                   queues.map { |q| [{ queue: q.name }, q.latency.round(3)] })
      end

      def collect_sidekiq_processes
        processes = Sidekiq::ProcessSet.new.to_a
        @out.gauge('library_sidekiq_processes', 'Running Sidekiq processes.', processes.size)
        @out.gauge('library_sidekiq_servers', 'Distinct hosts running Sidekiq.', processes.pluck('hostname').uniq.size)
        @out.gauge('library_sidekiq_process_info', 'Sidekiq process details.',
                   processes.map { |p| [process_info_labels(p), 1] })
        process_gauges(processes)
      end

      def process_gauges(processes)
        {
          'library_sidekiq_process_concurrency' => ['Thread capacity per process.', 'concurrency'],
          'library_sidekiq_process_busy' => ['Busy threads per process.', 'busy'],
          'library_sidekiq_process_started_timestamp_seconds' => ['Process start, unix time.', 'started_at'],
          'library_sidekiq_process_rss_kilobytes' => ['Resident memory per process.', 'rss'],
          'library_sidekiq_process_quiet' => ['1 if the process is quiet (shutting down).', 'quiet']
        }.each do |name, (help, field)|
          @out.gauge(name, help, processes.map { |p| [process_labels(p), numeric(p[field])] })
        end
      end

      def process_info_labels(process)
        process_labels(process).merge(version: process['version'], queues: Array(process['queues']).join(','),
                                      tag: process['tag'].to_s)
      end

      def process_labels(process)
        { hostname: process['hostname'], pid: process['pid'] }
      end

      def numeric(value)
        case value
        when true, 'true' then 1
        when false, nil, 'false' then 0
        else value.to_f
        end
      end

      def collect_sidekiq_sets
        @out.gauge('library_sidekiq_retries_by_job', "Retrying jobs by class (first #{SET_SCAN_LIMIT} scanned).",
                   tally(Sidekiq::RetrySet.new))
        @out.gauge('library_sidekiq_dead_by_job', "Dead jobs by class (first #{SET_SCAN_LIMIT} scanned).",
                   tally(Sidekiq::DeadSet.new))
        @out.gauge('library_sidekiq_scheduled_by_job', "Scheduled jobs by class (first #{SET_SCAN_LIMIT} scanned).",
                   tally(Sidekiq::ScheduledSet.new))
        busy = Sidekiq::WorkSet.new.map { |_pid, _tid, work| work.job.display_class }.tally
        @out.gauge('library_sidekiq_running_by_job', 'Jobs running right now, by class.',
                   busy.map { |job, n| [{ job: job }, n] })
      end

      def tally(set)
        counts = Hash.new(0)
        set.each_with_index do |entry, index|
          break if index >= SET_SCAN_LIMIT

          counts[entry.display_class] += 1
        end
        counts.map { |job, n| [{ job: job }, n] }
      end

      def collect_sidekiq_cron
        return unless defined?(::Sidekiq::Cron::Job)

        jobs = ::Sidekiq::Cron::Job.all
        @out.gauge('library_sidekiq_cron_job_info', 'Scheduled recurring jobs.',
                   jobs.map { |j| [{ name: j.name, job: j.klass, cron: j.cron, status: j.status }, 1] })
        @out.gauge('library_sidekiq_cron_last_enqueue_timestamp_seconds', 'Last run of each recurring job, unix time.',
                   jobs.map { |j| [{ name: j.name }, j.last_enqueue_time&.to_time.to_f] })
      end
    end
  end
end
