require 'stringio'

module Books
  module Metadata
    class CoverImporter
      CONTENT_TYPE_EXTENSIONS = {
        'image/jpeg' => '.jpg',
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/gif' => '.gif'
      }.freeze

      def self.attach_from_urls(book, urls)
        new(book, urls).attach
      end

      def initialize(book, urls)
        @book = book
        @urls = Array(urls).map(&:to_s).compact_blank.uniq
      end

      def attach
        @urls.each do |url|
          attach_from_url(url)
        rescue Faraday::Error, ActiveStorage::IntegrityError
          next
        end
      end

      private

      def attach_from_url(url)
        response = connection.get(url)
        return unless response.success?
        return if response.body.blank?

        filename = filename_for(url, response)
        checksum = Digest::MD5.base64digest(response.body)
        return if @book.covers.attachments.any? { |attachment| attachment.blob.checksum == checksum }

        @book.covers.attach(
          io: StringIO.new(response.body),
          filename: filename,
          content_type: response.headers['content-type'].presence || 'image/jpeg'
        )
      end

      def filename_for(url, response)
        extension = extension_from_content_type(response.headers['content-type'])
        extension ||= File.extname(URI.parse(url).path)
        extension = '.jpg' if extension.blank?
        "cover-#{Digest::SHA256.hexdigest(url)[0, 12]}#{extension}"
      end

      def extension_from_content_type(content_type)
        return nil if content_type.blank?

        CONTENT_TYPE_EXTENSIONS[content_type.split(';').first]
      end

      def connection
        @connection ||= Faraday.new do |faraday|
          faraday.response :follow_redirects
          faraday.options.timeout = 15
          faraday.options.open_timeout = 5
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
