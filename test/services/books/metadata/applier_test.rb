require 'test_helper'

module Books
  module Metadata
    class ApplierTest < ActiveSupport::TestCase
      setup do
        @result = Books::Metadata::Result.new(
          title: 'Filled Title',
          subtitle: 'Filled Subtitle',
          author_names: ['Jane Doe'],
          published_on: Date.new(2020, 1, 15),
          description: 'Filled description',
          publisher: 'Filled Publisher',
          page_count: 300,
          language: 'en',
          subjects: ['Programming'],
          cover_urls: ['https://example.com/cover.jpg'],
          source: 'open_library',
          source_url: 'https://openlibrary.org/isbn/9780201616224'
        )
      end

      test 'only_empty skips populated book fields' do
        book = books(:pragmatic)
        payload = Books::Metadata::Applier.call(result: @result, book:, only_empty: true)

        assert_nil payload[:title]
        assert payload[:description].present?
        assert payload[:cover_urls].present?
      end

      test 'fills all fields for new lookup' do
        payload = Books::Metadata::Applier.call(result: @result, book: nil, only_empty: false)

        assert_equal 'Filled Title', payload[:title]
        assert_equal ['Jane Doe'], payload[:author_names]
        assert_equal ['Programming'], payload[:subject_names]
        assert_equal 'open_library', payload[:metadata_source]
        assert_equal 'https://openlibrary.org/isbn/9780201616224', payload[:source_url]
        assert payload[:metadata_fetched_at].present?
      end
    end
  end
end
