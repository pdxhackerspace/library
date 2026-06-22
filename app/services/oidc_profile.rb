module OidcProfile
  module_function

  def slack_info(auth)
    slack_hash = find_slack_hash(auth)
    return if slack_hash.blank?

    uid = slack_hash['uid'] || slack_hash[:uid]
    name = slack_hash['name'] || slack_hash[:name]
    return if uid.blank?

    { uid: uid.to_s, name: name.to_s.presence }
  end

  def find_slack_hash(auth)
    profile_sources(auth).each do |source|
      slack = slack_from_source(source)
      return slack if slack.present?
    end

    nil
  end

  def profile_sources(auth)
    [
      auth.extra&.raw_info,
      OidcDebug.decode_jwt_payload(auth.credentials&.id_token)
    ].compact
  end

  def slack_from_source(source)
    return unless source.is_a?(Hash)

    slack = source['slack'] || source[:slack]
    slack.is_a?(Hash) ? slack : nil
  end
end
