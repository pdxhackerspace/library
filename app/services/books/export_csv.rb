require 'csv'

module Books
  class ExportCsv
    HEADERS = %w[
      id title subtitle authors subjects location publisher published_on isbns
      copies_count language page_count description ebook_url notes metadata_source
      source_url metadata_fetched_at created_at updated_at
    ].freeze

    EXTRACTORS = {
      'id' => ->(book) { book.id },
      'title' => ->(book) { book.title },
      'subtitle' => ->(book) { book.subtitle },
      'authors' => ->(book) { ExportCsv.join_names(book.authors) },
      'subjects' => ->(book) { ExportCsv.join_names(book.subjects) },
      'location' => ->(book) { book.location&.name },
      'publisher' => ->(book) { book.publisher },
      'published_on' => ->(book) { book.published_on },
      'isbns' => ->(book) { book.isbn_codes.join(', ') },
      'copies_count' => ->(book) { book.copies_count },
      'language' => ->(book) { book.language },
      'page_count' => ->(book) { book.page_count },
      'description' => ->(book) { book.description },
      'ebook_url' => ->(book) { book.ebook_url },
      'notes' => ->(book) { book.notes },
      'metadata_source' => ->(book) { book.metadata_source },
      'source_url' => ->(book) { book.source_url },
      'metadata_fetched_at' => ->(book) { book.metadata_fetched_at },
      'created_at' => ->(book) { book.created_at },
      'updated_at' => ->(book) { book.updated_at }
    }.freeze

    def self.call
      new.call
    end

    def call
      CSV.generate do |csv|
        csv << HEADERS
        books.find_each { |book| csv << row_for(book) }
      end
    end

    def self.join_names(records)
      records.map(&:name).join(', ')
    end

    private

    def books
      Book.includes(:authors, :subjects, :location, :isbns).ordered
    end

    def row_for(book)
      HEADERS.map { |header| EXTRACTORS.fetch(header).call(book) }
    end
  end
end
