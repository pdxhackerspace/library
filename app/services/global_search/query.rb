module GlobalSearch
  Result = Data.define(:books, :authors, :subjects, :publishers, :users) do
    def total_count
      books.size + authors.size + subjects.size + publishers.size + users.size
    end

    def any?
      total_count.positive?
    end
  end

  class Query
    LIMIT = 15

    def self.call(query, include_users: true)
      new(query, include_users:).call
    end

    def initialize(query, include_users: true)
      @query = query.to_s.strip
      @include_users = include_users
    end

    def call
      return empty_result if @query.blank?

      Result.new(
        books: search_books.to_a,
        authors: search_authors.to_a,
        subjects: search_subjects.to_a,
        publishers: search_publishers,
        users: @include_users ? search_users.to_a : []
      )
    end

    private

    def empty_result
      Result.new(books: [], authors: [], subjects: [], publishers: [], users: [])
    end

    def pattern
      @pattern ||= "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    end

    def search_books
      Book.includes(:authors, :location)
          .left_joins(:location)
          .where(
            'books.title ILIKE :q OR books.subtitle ILIKE :q OR books.publisher ILIKE :q OR locations.name ILIKE :q',
            q: pattern
          )
          .ordered
          .limit(LIMIT)
    end

    def search_authors
      Author.with_inventory_counts
            .where('authors.name ILIKE ?', pattern)
            .order(:name)
            .limit(LIMIT)
    end

    def search_subjects
      Subject.with_inventory_counts
             .where('subjects.name ILIKE ?', pattern)
             .order(:name)
             .limit(LIMIT)
    end

    def search_publishers
      Book.where('publisher ILIKE ?', pattern)
          .where.not(publisher: [nil, ''])
          .group(:publisher)
          .order(Arel.sql('LOWER(publisher)'))
          .limit(LIMIT)
          .count
          .map { |name, count| PublisherResult.new(name:, books_count: count) }
    end

    def search_users
      User.where('name ILIKE :q OR email ILIKE :q', q: pattern)
          .order(:name)
          .limit(LIMIT)
    end
  end

  PublisherResult = Data.define(:name, :books_count)
end
