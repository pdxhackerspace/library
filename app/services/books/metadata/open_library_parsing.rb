module Books
  module Metadata
    module OpenLibraryParsing
      private

      def publisher_from(payload)
        extract_name(Array(payload['publishers']).first)
      end

      def subjects_from(payload)
        Array(payload['subjects']).filter_map { |subject| extract_name(subject) }.uniq
      end

      def extract_name(value)
        return nil if value.blank?
        return value.to_s.strip.presence if value.is_a?(String)
        return value['name'].to_s.strip.presence if value.is_a?(Hash)

        nil
      end
    end
  end
end
