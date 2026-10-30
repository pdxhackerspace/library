module BookFormLists
  extend ActiveSupport::Concern

  private

  def prepare_new_book_lists
    @book.isbn_codes_list = ['']
    @book.author_names_list = ['']
    @book.subject_names_list = ['']
    prepare_form_extras
  end

  def prepare_edit_book_lists
    @book.isbn_codes_list = @book.isbn_codes.presence || ['']
    @book.author_names_list = @book.author_names_list.presence || ['']
    @book.subject_names_list = @book.subject_names_list.presence || ['']
    prepare_form_extras
  end

  def prepare_form_extras
    @locations = Location.with_inventory_counts.ordered
  end

  def book_params
    attrs = params.expect(book: %i[
                            title subtitle published_on location_id notes ebook_url
                            description publisher page_count language copies_count
                            metadata_source source_url metadata_fetched_at
                          ])
    %i[author_names subject_names isbn_codes pending_cover_urls cover_uploads remove_cover_ids].each do |key|
      attrs[key] = Array(params.dig(:book, key))
    end
    attrs[:custom_location_name] = params.dig(:book, :custom_location_name)
    attrs
  end
end
