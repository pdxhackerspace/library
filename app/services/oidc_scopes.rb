module OidcScopes
  module_function

  def admin?(auth)
    scope_granted?(auth, OidcConfig.admin_scopes)
  end

  def editor?(auth)
    scope_granted?(auth, OidcConfig.editor_scopes)
  end

  def granted_scopes(auth)
    scope_sources(auth).flat_map { |value| parse_scopes(value) }.uniq
  end

  def scope_granted?(auth, required_scopes)
    granted_scopes(auth).intersect?(required_scopes)
  end

  def scope_sources(auth)
    [
      auth.credentials&.scope,
      scope_from_payload(OidcDebug.decode_jwt_payload(auth.credentials&.id_token)),
      scope_from_source(auth.extra&.raw_info)
    ].compact
  end

  def scope_from_payload(payload)
    return if payload.blank?

    payload['scope'] || payload[:scope]
  end

  def scope_from_source(source)
    return unless source.is_a?(Hash)

    source['scope'] || source[:scope]
  end

  def parse_scopes(value)
    value.to_s.split(/\s+/).map(&:strip).compact_blank
  end
end
