Rails.application.routes.default_url_options = if ENV['APP_BASE_URL'].present?
                                                   uri = URI.parse(ENV['APP_BASE_URL'])
                                                   options = {
                                                     host: uri.host,
                                                     protocol: uri.scheme
                                                   }
                                                   if uri.port && uri.port != uri.default_port
                                                     options[:port] = uri.port
                                                   end
                                                   options
                                                 else
                                                   Rails.application.config.action_mailer.default_url_options || {}
                                                 end
