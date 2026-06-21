module Books
  module Metadata
    class OpenLibraryClient
      include OpenLibraryParsing

      BASE_URL = 'https://openlibrary.org/api/books'.freeze

      def self.call(isbn)
        new(isbn).call
      end

      def initialize(isbn)
        @isbn = IsbnCode.normalize(isbn)
      end

      def call
        return nil if @isbn.blank?

        payload = fetch_data
        return nil if payload.blank?

        build_result(payload)
      end

      private

      def fetch_data
        response = connection.get(BASE_URL, {
                                    bibkeys: "ISBN:#{@isbn}",
                                    format: 'json',
                                    jscmd: 'data'
                                  })
        return nil unless response.success?

        body = JSON.parse(response.body)
        body["ISBN:#{@isbn}"]
      rescue JSON::ParserError, Faraday::Error
        nil
      end

      def build_result(payload)
        Result.new(**open_library_attributes(payload))
      end

      def open_library_attributes(payload)
        bibliographic_attributes(payload).merge(
          cover_urls: cover_urls_from(payload),
          source: 'open_library',
          source_url: payload['url'] || "https://openlibrary.org/isbn/#{@isbn}"
        )
      end

      def bibliographic_attributes(payload)
        {
          title: payload['title'].to_s.strip.presence,
          subtitle: nil,
          author_names: author_names_from(payload),
          published_on: parse_date(payload['publish_date']),
          description: extract_description(payload),
          publisher: publisher_from(payload),
          page_count: payload['number_of_pages'].presence,
          language: extract_language(Array(payload['languages']).first),
          subjects: subjects_from(payload)
        }
      end

      def cover_urls_from(payload)
        [
          payload.dig('cover', 'large'),
          payload.dig('cover', 'medium'),
          payload.dig('cover', 'small'),
          "https://covers.openlibrary.org/b/isbn/#{@isbn}-L.jpg",
          "https://covers.openlibrary.org/b/isbn/#{@isbn}-M.jpg"
        ].compact.uniq
      end

      def author_names_from(payload)
        Array(payload['authors']).filter_map { |author| author['name'].to_s.strip.presence }
      end

      def extract_description(payload)
        description = payload['description']
        return description.to_s.strip.presence if description.is_a?(String)
        return description['value'].to_s.strip.presence if description.is_a?(Hash)

        excerpt = payload['excerpt']
        return excerpt.to_s.strip.presence if excerpt.is_a?(String)
        return excerpt['value'].to_s.strip.presence if excerpt.is_a?(Hash)

        nil
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value.to_s)
      rescue ArgumentError
        year = value.to_s[/\A(\d{4})/, 1]
        year ? Date.new(year.to_i, 1, 1) : nil
      end

      def extract_language(value)
        return nil if value.blank?
        return value.to_s.strip.presence unless value.is_a?(Hash)

        value['key']&.split('/')&.last.presence
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
