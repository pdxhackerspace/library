require 'test_helper'

module Books
  class NfcTagPayloadTest < ActiveSupport::TestCase
    setup do
      @original_max_bytes = ENV.fetch('NFC_TAG_MAX_BYTES', nil)
      @book = books(:pragmatic)
      @builder = NfcTagPayload.new(@book)
      @url = @builder.send(:book_url, @book, **@builder.send(:route_url_options))
      @fields = @builder.send(:build_fields, @url)
    end

    teardown do
      if @original_max_bytes
        ENV['NFC_TAG_MAX_BYTES'] = @original_max_bytes
      else
        ENV.delete('NFC_TAG_MAX_BYTES')
      end
    end

    test 'builds url and json for a book' do
      result = NfcTagPayload.call(@book)

      assert_match(%r{/books/#{@book.id}\z}, result.url)
      payload = JSON.parse(result.json)
      assert_equal result.url, payload['link']
      assert_match(%r{\Ahttps?://}, payload['link'])
      assert_equal @book.id, payload['library_uid']
      assert_equal '9780201616224', payload['isbn']
      assert_equal 'The Pragmatic Programmer', payload['title']
      assert_includes payload['authors'], 'David Thomas'
      assert_equal 'Shelf B2', payload['location']
      assert_not result.json_truncated
      assert result.estimated_bytes.positive?
    end

    test 'preserves isbn and url when truncating metadata' do
      full_size = @builder.send(:estimate_ndef_bytes, @url, @fields)
      ENV['NFC_TAG_MAX_BYTES'] = (full_size - 1).to_s

      result = NfcTagPayload.call(@book)
      payload = JSON.parse(result.json)

      assert result.json_truncated
      assert_equal result.url, payload['link']
      assert_equal @book.id, payload['library_uid']
      assert_equal '9780201616224', payload['isbn']
      assert_match(%r{/books/#{@book.id}\z}, result.url)
      assert result.estimated_bytes <= ENV['NFC_TAG_MAX_BYTES'].to_i
    end

    test 'truncates authors before location and title' do
      without_authors = @fields.merge(authors: '')
      size_without_authors = @builder.send(:estimate_ndef_bytes, @url, without_authors)
      ENV['NFC_TAG_MAX_BYTES'] = (size_without_authors + 1).to_s

      result = NfcTagPayload.call(@book)
      payload = JSON.parse(result.json)

      assert result.json_truncated
      assert_not_equal @fields[:authors], payload['authors']
      assert_equal @fields[:location], payload['location']
      assert_equal @fields[:title], payload['title']
    end

    test 'truncates location after authors are exhausted' do
      without_authors = @fields.merge(authors: '')
      without_authors_or_location = without_authors.merge(location: '')
      size_without_authors_or_location = @builder.send(:estimate_ndef_bytes, @url, without_authors_or_location)
      ENV['NFC_TAG_MAX_BYTES'] = (size_without_authors_or_location + 1).to_s

      result = NfcTagPayload.call(@book)
      payload = JSON.parse(result.json)

      assert result.json_truncated
      assert_equal '', payload['authors']
      assert_not_equal @fields[:location], payload['location']
      assert_equal @fields[:title], payload['title']
    end

    test 'truncates title after authors and location are exhausted' do
      cleared = @fields.merge(authors: '', location: '')
      full_cleared_size = @builder.send(:estimate_ndef_bytes, @url, cleared)
      ENV['NFC_TAG_MAX_BYTES'] = (full_cleared_size - 1).to_s

      result = NfcTagPayload.call(@book)
      payload = JSON.parse(result.json)

      assert result.json_truncated
      assert_equal '', payload['authors']
      assert_equal '', payload['location']
      assert_not_equal @fields[:title], payload['title'].delete_suffix(NfcTagPayload::TRUNCATION_SUFFIX)
    end

    test 'handles missing optional fields' do
      book = books(:electronics)

      result = NfcTagPayload.call(book)
      payload = JSON.parse(result.json)

      assert_equal result.url, payload['link']
      assert_equal book.id, payload['library_uid']
      assert_equal '', payload['isbn']
      assert_equal 'Make Electronics', payload['title']
      assert_equal 'Shelf A1', payload['location']
    end
  end
end
