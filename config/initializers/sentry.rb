module SentryConfig
  module_function

  def configured?
    dsn.present? && !Rails.env.test?
  end

  def dsn
    ENV['SENTRY_DSN'].presence
  end

  def environment
    ENV.fetch('SENTRY_ENVIRONMENT', Rails.env)
  end

  def traces_sample_rate
    Float(ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', 0))
  rescue ArgumentError
    0.0
  end
end

if SentryConfig.configured?
  Sentry.init do |config|
    config.dsn = SentryConfig.dsn
    config.environment = SentryConfig.environment
    config.release = AppInfo.version
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.traces_sample_rate = SentryConfig.traces_sample_rate
    config.send_default_pii = false
  end
end
