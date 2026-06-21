module OidcDebug
  module_function

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('OIDC_DEBUG', 'false'))
  end

  def log(message)
    return unless enabled?

    Rails.logger.info("[OIDC] #{message}")
  end

  def log_json(label, data)
    return unless enabled?

    payload = data.is_a?(String) ? data : JSON.pretty_generate(deep_stringify(data))
    Rails.logger.info("[OIDC] #{label}:\n#{payload}")
  end

  def log_request(env)
    return unless enabled?

    request = Rack::Request.new(env)
    log_json(
      "Request #{request.request_method} #{request.path}",
      {
        query: request.GET.to_h,
        form: request.POST.to_h,
        headers: env.select { |key, _| key.start_with?('HTTP_') }
                    .transform_keys { |key| key.sub(/\AHTTP_/, '').tr('_', '-').downcase }
      }
    )
  end

  def log_auth(auth)
    return unless enabled?

    log_json('OmniAuth response', auth_payload(auth))
  end

  def log_failure(env)
    return unless enabled?

    request = Rack::Request.new(env)
    log_json(
      'OmniAuth failure',
      {
        path: request.path,
        query: request.GET.to_h,
        message: request.GET['message'],
        error: request.GET['error'],
        error_description: request.GET['error_description']
      }
    )
  end

  def log_configuration
    return unless enabled?

    log_json(
      'OIDC configuration',
      {
        issuer: OidcConfig.issuer,
        client_id: OidcConfig.client_id,
        client_secret: OidcConfig.client_secret.present? ? '[present]' : nil,
        redirect_uri: OidcConfig.redirect_uri,
        admin_claims: OidcConfig.admin_claim_keys,
        editor_claims: OidcConfig.editor_claim_keys,
        admin_groups: OidcConfig.admin_groups,
        editor_groups: OidcConfig.editor_groups
      }
    )
  end

  def auth_payload(auth)
    payload = deep_stringify(auth.to_hash)
    id_token = auth.credentials&.id_token
    payload['decoded_id_token'] = decode_jwt_payload(id_token) if id_token.present?
    payload
  end

  def decode_jwt_payload(token)
    segment = token.to_s.split('.')[1]
    return nil if segment.blank?

    padding = (4 - (segment.length % 4)) % 4
    padded = segment + ('=' * padding)
    JSON.parse(Base64.urlsafe_decode64(padded))
  rescue JSON::ParserError, ArgumentError
    nil
  end

  def deep_stringify(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, nested), result|
        result[key.to_s] = deep_stringify(nested)
      end
    when Array
      value.map { |item| deep_stringify(item) }
    else
      value
    end
  end
end
