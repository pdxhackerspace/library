require 'test_helper'

class MetricsConfigTest < ActiveSupport::TestCase
  test 'initializer defers constant references until after initialization' do
    source = Rails.root.join('config/initializers/metrics.rb').read
    top_level = source.lines.reject { |line| line.start_with?('#') || line.start_with?(' ') }.join

    assert_no_match(/Metrics::/, top_level)
  end
end
