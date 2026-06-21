ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

require Rails.root.join('test/support/sign_in_helper')
require Rails.root.join('test/support/integration_test')

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end
