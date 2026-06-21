module Books
  module Metadata
    class Lookup
      def self.call(isbn)
        new(isbn).call
      end

      def initialize(isbn)
        @isbn = isbn
      end

      def call
        open_library_result = OpenLibraryClient.call(@isbn)
        return open_library_result if open_library_result.present?

        GoogleBooksClient.call(@isbn)
      end
    end
  end
end
