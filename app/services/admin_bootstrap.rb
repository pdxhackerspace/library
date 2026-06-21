module AdminBootstrap
  module_function

  def admin_email
    ENV['ADMIN_EMAIL'].to_s.strip.downcase
  end

  def call
    email = admin_email
    password = ENV['ADMIN_PASSWORD'].to_s
    name = ENV.fetch('ADMIN_NAME', 'Library Admin')

    return if email.blank? || password.blank?

    user = User.find_or_initialize_by(email: email)
    user.name = name
    user.admin = true
    user.password = password if user.new_record?
    user.save!
  end
end
