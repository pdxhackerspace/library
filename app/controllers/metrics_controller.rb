# Prometheus scrape endpoint. Disabled (404) unless METRICS_TOKEN is set;
# otherwise requires `Authorization: Bearer <METRICS_TOKEN>`.
class MetricsController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :require_enabled
  before_action :authenticate_token

  def show
    render plain: Metrics::Collector.new.call, content_type: Metrics::Exposition::CONTENT_TYPE
  end

  private

  def require_enabled
    head :not_found unless Metrics::Store.enabled?
  end

  def authenticate_token
    return if authenticate_with_http_token { |given, _options| valid_token?(given) }

    headers['WWW-Authenticate'] = 'Bearer realm="Library metrics"'
    render plain: "A valid metrics token is required.\n", status: :unauthorized
  end

  # Compare digests so the check is constant-time regardless of length.
  def valid_token?(given)
    ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(given.to_s),
                                                Digest::SHA256.hexdigest(Metrics::Store.token))
  end
end
