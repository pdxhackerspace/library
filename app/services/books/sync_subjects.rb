module Books
  class SyncSubjects
    def self.call(book, names)
      new(book, names).call
    end

    def initialize(book, names)
      @book = book
      @names = Array(names).map(&:to_s).map(&:strip).compact_blank.uniq
    end

    def call
      @book.book_subjects.destroy_all

      @names.each_with_index do |name, index|
        subject = Subject.where('lower(name) = ?', name.downcase).first_or_create!(name: name)
        @book.book_subjects.create!(subject: subject, position: index)
      end
    end
  end
end
