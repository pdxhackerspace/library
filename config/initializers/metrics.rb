# Prometheus metrics (see docs/metrics.md). Recording is a no-op until
# METRICS_TOKEN is set.
Rails.application.config.after_initialize do
  Metrics::RequestRecorder.subscribe!
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Metrics::SidekiqMiddleware
  end
end
