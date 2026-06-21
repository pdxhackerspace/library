module InventoryCounts
  extend ActiveSupport::Concern

  class_methods do
    def with_inventory_counts
      left_joins(:books)
        .select("#{table_name}.*, COUNT(books.id) AS books_count, COALESCE(SUM(books.copies_count), 0) AS copies_count")
        .group("#{table_name}.id")
    end
  end
end
