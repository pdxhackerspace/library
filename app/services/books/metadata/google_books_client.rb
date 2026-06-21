module Books
  module Metadata
    class GoogleBooksClient
      BASE_URL = 'https://www.googleapis.com/books/v1/volumes'.freeze

      def self.call(isbn)
        new(isbn).call
      end

      def initialize(isbn)
        @isbn = IsbnCode.normalize(isbn)
      end

      def call
        return nil if @isbn.blank?
        return nil if api_key.blank?

        item = fetch_item
        return nil if item.blank?

        build_result(item)
      end

      private

      def fetch_item
        response = connection.get(BASE_URL, {
                                    q: "isbn:#{@isbn}",
                                    key: api_key
                                  })
        return nil unless response.success?

        body = JSON.parse(response.body)
        body.dig('items', 0)
      rescue JSON::ParserError, Faraday::Error
        nil
      end

      def build_result(item)
        Result.new(**google_books_attributes(item))
      end

      def google_books_attributes(item)
        info = item.fetch('volumeInfo', {})

        bibliographic_attributes(info).merge(
          cover_urls: cover_urls_from(info),
          source: 'google_books',
          source_url: info['infoLink'].presence || info['previewLink'].presence || item['selfLink']
        )
      end

      def bibliographic_attributes(info)
        {
          title: text_field(info, 'title'),
          subtitle: text_field(info, 'subtitle'),
          author_names: author_names_from_info(info),
          published_on: parse_date(info['publishedDate']),
          description: strip_html(info['description']),
          publisher: text_field(info, 'publisher'),
          page_count: info['pageCount'].presence,
          language: text_field(info, 'language'),
          subjects: subjects_from_info(info)
        }
      end

      def text_field(info, key)
        info[key].to_s.strip.presence
      end

      def author_names_from_info(info)
        Array(info['authors']).map { |name| name.to_s.strip }.compact_blank
      end

      def subjects_from_info(info)
        Array(info['categories']).map { |subject| subject.to_s.strip }.compact_blank
      end

      def cover_urls_from(info)
        [
          info.dig('imageLinks', 'extraLarge'),
          info.dig('imageLinks', 'large'),
          info.dig('imageLinks', 'medium'),
          info.dig('imageLinks', 'small'),
          info.dig('imageLinks', 'thumbnail'),
          info.dig('imageLinks', 'smallThumbnail')
        ].compact.map { |url| url.gsub('http://', 'https://') }.uniq
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value.to_s)
      rescue ArgumentError
        year = value.to_s[/\A(\d{4})/, 1]
        year ? Date.new(year.to_i, 1, 1) : nil
      end

      def strip_html(text)
        return nil if text.blank?

        ActionController::Base.helpers.strip_tags(text.to_s).squish.presence
      end

      def api_key
        ENV['GOOGLE_BOOKS_API_KEY'].to_s.strip.presence
      end

      def connection
        @connection ||= Faraday.new do |faraday|
          faraday.response :follow_redirects
          faraday.options.timeout = 10
          faraday.options.open_timeout = 5
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
