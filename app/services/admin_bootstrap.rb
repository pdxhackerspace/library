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

    user = User.find_by(email: email)
    if user.nil?
      User.create!(email: email, name: name, admin: true, password: password)
    else
      user.update!(name: name, admin: true)
    end
  end
end
