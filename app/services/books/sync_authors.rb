module Books
  class SyncAuthors
    def self.call(book, names)
      new(book, names).call
    end

    def initialize(book, names)
      @book = book
      @names = normalize(names)
    end

    def call
      @book.book_authors.destroy_all

      @names.each_with_index do |name, index|
        author = Author.where('lower(name) = ?', name.downcase).first_or_create!(name: name)
        @book.book_authors.create!(author: author, position: index)
      end
    end

    private

    def normalize(names)
      list = names.is_a?(String) ? AuthorNames.parse(names) : Array(names)
      list.map(&:to_s).map(&:strip).compact_blank.uniq
    end
  end
end
