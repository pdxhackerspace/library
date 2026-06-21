module Books
  module AuthorNames
    module_function

    def parse(text)
      text.to_s.split(/[\n,]+/).map { |name| name.strip.gsub(/\s+/, ' ') }.compact_blank.uniq
    end
  end
end
