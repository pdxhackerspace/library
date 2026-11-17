require 'sidekiq/api'

module Metrics
  module Collectors
    module Jobs
      def collect_jobs
        series = JobRecorder.read
        @out.counter('library_job_executions_total', 'Job executions by outcome.',
                     series.flat_map { |s| job_outcomes(s) })
        @out.histogram('library_job_duration_seconds', 'Job run time in seconds.',
                       series.to_h { |s| [{ job: s[:job], queue: s[:queue] }, histogram_data(s, executions(s))] })
        @out.gauge('library_job_last_run_timestamp_seconds', 'Last finish per job class and outcome, unix time.',
                   JobRecorder.last_runs.map { |job, status, at| [{ job: job, status: status }, at] })
      end

      def executions(entry)
        entry[:success] + entry[:failure]
      end

      def job_outcomes(entry)
        %i[success failure].map { |status| [{ job: entry[:job], queue: entry[:queue], status: status }, entry[status]] }
      end
    end
  end
end
