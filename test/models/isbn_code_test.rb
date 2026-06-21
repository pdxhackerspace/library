require 'test_helper'

class IsbnCodeTest < ActiveSupport::TestCase
  test 'normalizes isbn values' do
    assert_equal '9780201616224', IsbnCode.normalize('978-0-201-61622-4')
  end

  test 'validates isbn13 codes' do
    assert IsbnCode.valid?('9780201616224')
    assert_not IsbnCode.valid?('9780201616225')
  end
end
