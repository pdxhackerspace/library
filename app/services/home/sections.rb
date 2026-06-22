module Home
  class Sections
    SECTION_LIMIT = 12
    LIST_INCLUDES = [:authors, :location, { loans: :user }].freeze

    def self.call
      new.call
    end

    def call
      featured_subject = random_subject

      {
        recent_books: list_scope.recently_added(SECTION_LIMIT),
        random_books: list_scope.random_sample(SECTION_LIMIT),
        popular_books: list_scope.popular(SECTION_LIMIT),
        featured_subject: featured_subject,
        subject_books: subject_books_for(featured_subject)
      }
    end

    private

    def list_scope
      Book.includes(LIST_INCLUDES)
    end

    def random_subject
      Subject.joins(:books).group('subjects.id').order(Arel.sql('RANDOM()')).first
    end

    def subject_books_for(subject)
      return Book.none if subject.nil?

      subject.books.includes(LIST_INCLUDES).ordered.limit(SECTION_LIMIT)
    end
  end
end
