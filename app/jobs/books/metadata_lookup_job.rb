module Books
  class MetadataLookupJob < ApplicationJob
    queue_as :default

    def perform(lookup_token:, isbn:, book_id: nil, only_empty: false)
      book = Book.find_by(id: book_id)
      result = Metadata::Lookup.call(isbn)

      if result.nil?
        broadcast_status(lookup_token, :not_found, book)
        return
      end

      payload = Metadata::Applier.call(result:, book:, only_empty: only_empty)

      if book.present? && only_empty
        Metadata::Applier.new(result:, book:, only_empty: true).apply_to_book!(book)
        book.reload
      end

      broadcast_update(lookup_token, payload, book, status: :success)
    end

    private

    def broadcast_status(lookup_token, status, book)
      broadcast_update(lookup_token, {}, book, status: status)
    end

    def broadcast_update(lookup_token, payload, book, status:)
      Turbo::StreamsChannel.broadcast_render_to(
        "book_metadata_lookup_#{lookup_token}",
        partial: 'books/metadata_lookup',
        locals: {
          payload: payload,
          book: book,
          status: status
        }
      )
    end
  end
end
