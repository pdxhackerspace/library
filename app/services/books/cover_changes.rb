module Books
  # Applies cover photos uploaded or removed from the book form.
  class CoverChanges
    CONTENT_TYPES = Metadata::CoverImporter::CONTENT_TYPE_EXTENSIONS.keys.freeze
    MAX_SIZE = 10.megabytes

    def initialize(book, params)
      @book = book
      @params = params
    end

    def errors
      @errors ||= uploads.filter_map do |upload|
        name = upload.original_filename
        if CONTENT_TYPES.exclude?(upload.content_type)
          "Cover #{name} must be a JPEG, PNG, WebP, or GIF image"
        elsif upload.size > MAX_SIZE
          "Cover #{name} must be smaller than 10 MB"
        end
      end
    end

    def valid?
      errors.empty?
    end

    def removing?
      remove_ids.any?
    end

    def apply!
      remove!
      @book.covers.attach(uploads) if uploads.any?
    end

    private

    def uploads
      Array(@params[:cover_uploads]).select { |upload| upload.respond_to?(:content_type) }
    end

    def remove_ids
      Array(@params[:remove_cover_ids]).compact_blank
    end

    def remove!
      return unless removing?

      @book.covers.attachments.where(id: remove_ids).find_each(&:purge_later)
      @book.covers_attachments.reset
    end
  end
end
