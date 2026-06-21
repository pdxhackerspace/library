require 'test_helper'

class BookTest < ActiveSupport::TestCase
  test 'validates ebook url format' do
    book = books(:pragmatic)
    book.ebook_url = 'not-a-url'

    assert_not book.valid?
    assert_includes book.errors[:ebook_url], 'is invalid'
  end

  test 'allows blank ebook url' do
    book = books(:pragmatic)
    book.ebook_url = '  '

    assert book.valid?
    assert_nil book.ebook_url
  end
end
