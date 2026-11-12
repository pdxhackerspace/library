module Books
  # Serializes the catalog as JSON Lines (one book per line) for search and
  # RAG indexers. Only static catalog data is included: no loans, borrowers,
  # availability, or view/borrow counters.
  class CatalogFeed
    TEXT_FIELDS = [
      ['Title', :full_title],
      ['Authors', ->(record) { record[:authors].join(', ') }],
      ['Subjects', ->(record) { record[:subjects].join(', ') }],
      ['Publisher', :publisher],
      ['Published', :published_on],
      ['Language', :language],
      ['Pages', :page_count],
      ['ISBN', ->(record) { record[:isbns].join(', ') }],
      ['Location', :location],
      ['Added to library', :added_on],
      ['Description', :description],
      ['Notes', :notes]
    ].freeze

    def initialize(url_options:, since: nil)
      @url_options = url_options
      @since = since
    end

    def each_line
      return enum_for(:each_line) unless block_given?

      books.find_each { |book| yield "#{record_for(book).to_json}\n" }
    end

    def call
      each_line.to_a.join
    end

    def record_for(book)
      record = base_record(book)
      record[:text] = text_for(record)
      record.except(:full_title)
    end

    private

    def books
      scope = Book.includes({ book_authors: :author }, { book_subjects: :subject }, :location, :isbns,
                            covers_attachments: :blob)
      scope = scope.where(updated_at: @since..) if @since
      scope
    end

    def base_record(book)
      {
        **identity(book),
        **people_and_topics(book),
        **publication(book),
        location: book.location&.name,
        copies_count: book.copies_count,
        description: book.description,
        notes: book.notes,
        ebook_url: book.ebook_url,
        cover_url: cover_url(book),
        **provenance(book)
      }
    end

    def identity(book)
      {
        id: book.id,
        url: url_helpers.book_url(book, **@url_options),
        title: book.title,
        subtitle: book.subtitle,
        full_title: [book.title, book.subtitle.presence].compact.join(': ')
      }
    end

    def people_and_topics(book)
      {
        authors: book.book_authors.map { |book_author| book_author.author.name },
        subjects: book.book_subjects.map { |book_subject| book_subject.subject.name },
        isbns: book.isbns.sort_by(&:id).map(&:code)
      }
    end

    def publication(book)
      {
        publisher: book.publisher,
        published_on: book.published_on&.iso8601,
        language: book.language,
        page_count: book.page_count
      }
    end

    def provenance(book)
      {
        metadata_source: book.metadata_source,
        source_url: book.source_url,
        added_on: book.created_at.to_date.iso8601,
        added_at: book.created_at.iso8601,
        updated_at: book.updated_at.iso8601
      }
    end

    def cover_url(book)
      cover = book.covers_attachments.min_by(&:id)
      return nil unless cover

      url_helpers.rails_blob_url(cover, **@url_options)
    end

    def text_for(record)
      TEXT_FIELDS.filter_map do |label, field|
        value = field.is_a?(Proc) ? field.call(record) : record[field]
        "#{label}: #{value}" if value.present?
      end.join("\n")
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end
end
