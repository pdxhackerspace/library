module Books
  class Save
    METADATA_FIELDS = %i[
      title subtitle published_on notes description publisher page_count language copies_count ebook_url
      source_url metadata_source metadata_fetched_at
    ].freeze

    def initialize(book, params)
      @book = book
      @params = params
    end

    def call
      @book.assign_attributes(book_attributes)
      assign_location!
      @book.author_names_list = author_names_list
      @book.subject_names_list = subject_names_list
      @book.isbn_codes_list = isbn_codes_list

      Book.transaction do
        @book.save!
        sync_authors!
        sync_subjects!
        sync_isbns!
        attach_pending_covers!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    private

    def book_attributes
      @params.slice(*METADATA_FIELDS)
    end

    def assign_location!
      location_id = @params[:location_id].presence
      custom = @params[:custom_location_name].to_s.strip

      if location_id.present?
        @book.location_id = location_id
      elsif custom.present?
        @book.location = Location.find_or_create_by_name!(custom)
      else
        @book.location = nil
      end
    end

    def author_names_list
      if @params.key?(:author_names)
        Array(@params[:author_names]).map(&:to_s).map(&:strip).compact_blank
      else
        AuthorNames.parse(@params[:author_names_text])
      end
    end

    def isbn_codes_list
      Array(@params[:isbn_codes]).map(&:to_s).map(&:strip).compact_blank
    end

    def subject_names_list
      Array(@params[:subject_names]).map(&:to_s).map(&:strip).compact_blank
    end

    def sync_subjects!
      SyncSubjects.call(@book, subject_names_list)
    end

    def pending_cover_urls
      Array(@params[:pending_cover_urls]).map(&:to_s).compact_blank.uniq
    end

    def sync_authors!
      SyncAuthors.call(@book, author_names_list)
    end

    def sync_isbns!
      codes = isbn_codes_list.map { |code| IsbnCode.normalize(code) }.uniq
      @book.isbns.destroy_all

      codes.each do |code|
        @book.isbns.create!(code: code)
      end
    end

    def attach_pending_covers!
      return if pending_cover_urls.blank?
      return if @book.covers_attached?

      Metadata::CoverImporter.attach_from_urls(@book, pending_cover_urls)
    end
  end
end
