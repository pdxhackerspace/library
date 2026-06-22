require 'test_helper'

module Books
  class ExportCsvTest < ActiveSupport::TestCase
    test 'exports books with comma-separated related names' do
      csv = ExportCsv.call
      rows = CSV.parse(csv, headers: true)

      pragmatic = rows.find { |row| row['title'] == books(:pragmatic).title }
      electronics = rows.find { |row| row['title'] == books(:electronics).title }

      assert_equal 'David Thomas, Andrew Hunt', pragmatic['authors']
      assert_equal 'Shelf B2', pragmatic['location']
      assert_includes pragmatic['isbns'], '9780201616224'

      assert_equal 'Charles Platt', electronics['authors']
      assert_equal 'Shelf A1', electronics['location']
    end
  end
end
