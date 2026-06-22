class ApplicationMailer < ActionMailer::Base
  default from: -> { MailConfig.smtp_from || 'library@example.com' }
  layout 'mailer'
end
