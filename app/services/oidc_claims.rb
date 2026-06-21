module OidcClaims
  module_function

  def admin?(auth)
    role?(auth, claim_keys: OidcConfig.admin_claim_keys, group_names: OidcConfig.admin_groups)
  end

  def editor?(auth)
    role?(auth, claim_keys: OidcConfig.editor_claim_keys, group_names: OidcConfig.editor_groups)
  end

  def role?(auth, claim_keys:, group_names:)
    claim_keys.each do |key|
      sources(auth).each do |source|
        value = extract(source, key)
        next if value.nil?

        return true if truthy?(value)
      end
    end

    group_names.intersect?(group_values(auth))
  end

  def sources(auth)
    [
      auth.extra&.raw_info,
      OidcDebug.decode_jwt_payload(auth.credentials&.id_token),
      auth.info
    ].compact
  end

  def value_for(auth, key)
    sources(auth).each do |source|
      value = extract(source, key)
      return value unless value.nil?
    end

    nil
  end

  def extract(source, key)
    return if source.nil?

    extract_from_hash(source, key) ||
      extract_from_indexable(source, key) ||
      extract_from_method(source, key)
  end

  def extract_from_hash(source, key)
    return unless source.is_a?(Hash)

    return source[key.to_s] if source.key?(key.to_s)
    return source[key.to_sym] if source.key?(key.to_sym)

    nil
  end

  def extract_from_indexable(source, key)
    return if source.is_a?(Hash)
    return unless source.respond_to?(:[])

    source[key.to_s] || source[key.to_sym]
  rescue NameError
    nil
  end

  def extract_from_method(source, key)
    source.public_send(key) if source.respond_to?(key)
  end

  def group_values(auth)
    sources(auth).flat_map { |source| Array(extract(source, 'groups')) }.map(&:to_s).uniq
  end

  def truthy?(value)
    case value
    when true then true
    when false, nil then false
    when String then %w[true 1 yes on t].include?(value.strip.downcase)
    when Numeric then !value.zero?
    else value.present?
    end
  end
end
