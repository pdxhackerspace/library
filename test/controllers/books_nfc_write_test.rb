require 'test_helper'

class BooksNfcWriteTest < ActionDispatch::IntegrationTest
  test 'editor sees nfc write controls on book show' do
    sign_in_as(users(:editor))
    book = books(:pragmatic)

    get book_path(book)

    assert_response :success
    assert_match 'Write NFC tag', response.body
    assert_match 'Copy book link', response.body
    assert_match payload.url, response.body
  end

  test 'write nfc redirect shows nfc prompt on book show' do
    sign_in_as(users(:editor))
    book = books(:pragmatic)

    get book_path(book, write_nfc: 1)

    assert_response :success
    assert_match 'Book saved. Tap Write NFC tag', response.body
    assert_match 'NFC tag', response.body
  end

  test 'member does not see nfc write controls on book show' do
    sign_in_local(users(:member))
    book = books(:pragmatic)

    get book_path(book)

    assert_response :success
    assert_no_match 'Write NFC tag', response.body
    assert_no_match 'Copy book link', response.body
  end

  private

  def payload
    @payload ||= Books::NfcTagPayload.call(books(:pragmatic))
  end
end
