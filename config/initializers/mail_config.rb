module MailConfig
  module_function

  def configured?
    smtp_address.present? && smtp_from.present?
  end

  def smtp_address
    ENV.fetch('SMTP_ADDRESS', nil)
  end

  def smtp_port
    ENV.fetch('SMTP_PORT', '587').to_i
  end

  def smtp_username
    ENV['SMTP_USERNAME'].presence
  end

  def smtp_password
    ENV['SMTP_PASSWORD'].presence
  end

  def smtp_domain
    ENV.fetch('SMTP_DOMAIN', smtp_address.to_s)
  end

  def smtp_from
    ENV['SMTP_FROM'].presence
  end

  def smtp_authentication
    return nil if smtp_username.blank?

    ENV.fetch('SMTP_AUTHENTICATION', 'plain')
  end

  def smtp_enable_starttls_auto
    ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', 'true') == 'true'
  end
end

if MailConfig.configured? && !Rails.env.test?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.smtp_settings = {
    address: MailConfig.smtp_address,
    port: MailConfig.smtp_port,
    domain: MailConfig.smtp_domain,
    user_name: MailConfig.smtp_username,
    password: MailConfig.smtp_password,
    authentication: MailConfig.smtp_authentication,
    enable_starttls_auto: MailConfig.smtp_enable_starttls_auto
  }.compact
  Rails.application.config.action_mailer.default_options = { from: MailConfig.smtp_from }
end
