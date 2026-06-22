module SlackConfig
  module_function

  def configured?
    bot_token.present?
  end

  def bot_token
    ENV['SLACK_BOT_TOKEN'].presence
  end

  def api_url
    'https://slack.com/api/chat.postMessage'
  end
end
