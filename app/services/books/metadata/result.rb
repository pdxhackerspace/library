module Books
  module Metadata
    Result = Data.define(
      :title,
      :subtitle,
      :author_names,
      :published_on,
      :description,
      :publisher,
      :page_count,
      :language,
      :subjects,
      :cover_urls,
      :source,
      :source_url
    ) do
      def present?
        title.present? || author_names.any? || description.present?
      end
    end
  end
end
