# Prometheus metrics (see docs/metrics.md). Recording is a no-op until
# METRICS_TOKEN is set.
#
# Metrics::* is autoloaded, and autoloading isn't available while initializers
# run (Sidekiq yields configure_server immediately), so defer to after_initialize.
Rails.application.config.after_initialize do
  Metrics::RequestRecorder.subscribe!

  Sidekiq.configure_server do |config|
    config.server_middleware { |chain| chain.add Metrics::SidekiqMiddleware }
  end
end
