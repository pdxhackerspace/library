module MetricsTestHelper
  TOKEN = 'test-metrics-token'.freeze

  # Isolates Redis keys per test (tests run in parallel against one Redis) and
  # turns metrics on with a known token.
  def with_metrics(token: TOKEN)
    previous_prefix = Metrics::Store.prefix
    previous_token = ENV.fetch('METRICS_TOKEN', nil)
    Metrics::Store.prefix = "test:metrics:#{SecureRandom.hex(6)}"
    ENV['METRICS_TOKEN'] = token
    yield
  ensure
    begin
      Metrics::Store.reset!
    rescue StandardError
      nil
    end
    Metrics::Store.prefix = previous_prefix
    ENV['METRICS_TOKEN'] = previous_token
  end
end
