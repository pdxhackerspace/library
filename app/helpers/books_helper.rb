module BooksHelper
  BOOK_WIZARD_STEPS = %w[ISBN Basics Subjects Location].freeze

  # Steps holding the fields each validation error belongs to; base errors are about authors.
  BOOK_WIZARD_ERROR_STEPS = {
    title: 1, base: 1, copies_count: 3, ebook_url: 3, location: 3, location_id: 3
  }.freeze

  def book_wizard_steps
    BOOK_WIZARD_STEPS
  end

  # Re-rendered forms open on the first step with an error; otherwise start at the ISBN step.
  def book_wizard_initial_step(book)
    return 0 if book.errors.empty?

    book.errors.attribute_names.filter_map { |name| BOOK_WIZARD_ERROR_STEPS[name] }.min || 0
  end
end
