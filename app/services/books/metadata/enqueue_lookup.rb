module Books
  module Metadata
    class EnqueueLookup
      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @params = params
      end

      def call
        return error('ISBN and lookup token are required.') if isbn.blank? || lookup_token.blank?
        return error('Invalid ISBN code.') unless IsbnCode.valid?(isbn)

        Books::MetadataLookupJob.perform_later(
          lookup_token: lookup_token,
          isbn: isbn,
          book_id: book&.id,
          only_empty: book.present?
        )

        success
      end

      private

      def book
        return @book if defined?(@book)

        @book = Book.find_by(id: @params[:id]) if @params[:id].present?
      end

      def isbn
        @isbn ||= IsbnCode.normalize(@params[:isbn])
      end

      def lookup_token
        @lookup_token ||= @params[:lookup_token].to_s
      end

      def error(message)
        { error: message, http_status: :unprocessable_content }
      end

      def success
        { status: 'queued', http_status: :accepted }
      end
    end
  end
end
