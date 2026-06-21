module Books
  module Metadata
    class Applier
      FIELD_MAP = {
        title: :title,
        subtitle: :subtitle,
        published_on: :published_on,
        description: :description,
        publisher: :publisher,
        page_count: :page_count,
        language: :language
      }.freeze

      def self.call(result:, book: nil, only_empty: false)
        new(result:, book:, only_empty:).call
      end

      def initialize(result:, book: nil, only_empty: false)
        @result = result
        @book = book
        @only_empty = only_empty
      end

      def call
        return {} if @result.nil?

        payload = build_field_payload
        attach_author_names!(payload)
        attach_subject_names!(payload)
        attach_metadata_fields!(payload)
        payload
      end

      def apply_to_book!(book)
        payload = call
        apply_scalar_attributes!(book, payload)
        apply_associations!(book, payload)
        book
      end

      private

      def apply_scalar_attributes!(book, payload)
        attrs = payload.except(:cover_urls, :author_names, :subject_names)
        book.update!(attrs) if attrs.any?
      end

      def apply_associations!(book, payload)
        Books::SyncAuthors.call(book, payload[:author_names]) if payload[:author_names].present?
        Books::SyncSubjects.call(book, payload[:subject_names]) if payload[:subject_names].present?

        cover_urls = payload[:cover_urls] || []
        return unless cover_urls.any? && !book.covers_attached?

        CoverImporter.attach_from_urls(book, cover_urls)
      end

      def build_field_payload
        FIELD_MAP.each_with_object({}) do |(field, result_key), payload|
          value = formatted_value(field, @result.public_send(result_key))
          next if value.blank?
          next if @only_empty && field_populated?(field)

          payload[field] = value
        end
      end

      def attach_author_names!(payload)
        return if skip_author_names?

        author_names = author_names_from_result
        payload[:author_names] = author_names if author_names.any?
      end

      def attach_subject_names!(payload)
        return if skip_subject_names?

        subject_names = subject_names_from_result
        payload[:subject_names] = subject_names if subject_names.any?
      end

      def skip_author_names?
        @only_empty && @book&.authors&.any?
      end

      def skip_subject_names?
        @only_empty && @book&.subjects&.any?
      end

      def author_names_from_result
        Array(@result.author_names).map(&:to_s).map(&:strip).compact_blank
      end

      def subject_names_from_result
        Array(@result.subjects).map(&:to_s).map(&:strip).compact_blank
      end

      def attach_metadata_fields!(payload)
        payload[:cover_urls] = @result.cover_urls if include_covers?
        payload[:metadata_source] = @result.source if @result.source.present?
        payload[:metadata_fetched_at] = Time.current if @result.source.present?
        payload[:source_url] = @result.source_url if @result.source_url.present?
      end

      def include_covers?
        return @result.cover_urls.any? unless @only_empty

        @result.cover_urls.any? && !@book&.covers_attached?
      end

      def field_populated?(field)
        return false if @book.nil?

        @book.public_send(field).present?
      end

      def formatted_value(field, value)
        case field
        when :published_on
          value&.iso8601
        else
          value.presence
        end
      end
    end
  end
end
