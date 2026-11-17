module Metrics
  # Sidekiq server middleware that times every job and records the outcome.
  class SidekiqMiddleware
    include Sidekiq::ServerMiddleware

    def call(worker, job, queue)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      success = false
      yield
      success = true
    ensure
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      JobRecorder.record(job_class(worker, job), queue, elapsed, success: success)
    end

    private

    # ActiveJob jobs run inside Sidekiq's JobWrapper; report the real class.
    def job_class(worker, job)
      job['wrapped'].presence || worker.class.name
    end
  end
end
