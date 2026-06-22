module Notifications
  class SlackMessenger
    def self.call(user:, text:)
      return false unless SlackConfig.configured?
      return false unless user.slack_linked?

      response = Faraday.post(
        SlackConfig.api_url,
        { channel: user.slack_uid, text: text }.to_json,
        {
          'Authorization' => "Bearer #{SlackConfig.bot_token}",
          'Content-Type' => 'application/json'
        }
      )

      body = JSON.parse(response.body)
      body['ok'] == true
    rescue Faraday::Error, JSON::ParserError
      false
    end
  end
end
