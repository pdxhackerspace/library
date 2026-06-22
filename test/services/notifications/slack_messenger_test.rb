require 'test_helper'

class NotificationsSlackMessengerTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
    @user.update!(slack_uid: 'U123', slack_name: 'member')
  end

  test 'posts message when slack is configured and user is linked' do
    with_slack_env(token: 'xoxb-test') do
      stub_request(:post, SlackConfig.api_url)
        .with(
          body: { channel: 'U123', text: 'Hello from the library' }.to_json,
          headers: { 'Authorization' => 'Bearer xoxb-test', 'Content-Type' => 'application/json' }
        )
        .to_return(status: 200, body: { ok: true }.to_json)

      assert Notifications::SlackMessenger.call(user: @user, text: 'Hello from the library')
    end
  end

  test 'returns false when slack is not configured' do
    with_slack_env(token: nil) do
      assert_not Notifications::SlackMessenger.call(user: @user, text: 'Hello')
    end
  end

  test 'returns false when user has no slack uid' do
    @user.update!(slack_uid: nil)

    with_slack_env(token: 'xoxb-test') do
      assert_not Notifications::SlackMessenger.call(user: @user, text: 'Hello')
    end
  end

  test 'returns false when slack api responds with error' do
    with_slack_env(token: 'xoxb-test') do
      stub_request(:post, SlackConfig.api_url)
        .to_return(status: 200, body: { ok: false, error: 'channel_not_found' }.to_json)

      assert_not Notifications::SlackMessenger.call(user: @user, text: 'Hello')
    end
  end

  private

  def with_slack_env(token:)
    original = ENV.fetch('SLACK_BOT_TOKEN', nil)
    if token.nil?
      ENV.delete('SLACK_BOT_TOKEN')
    else
      ENV['SLACK_BOT_TOKEN'] = token
    end
    yield
  ensure
    if original.nil?
      ENV.delete('SLACK_BOT_TOKEN')
    else
      ENV['SLACK_BOT_TOKEN'] = original
    end
  end
end
