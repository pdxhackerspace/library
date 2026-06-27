require 'test_helper'

module Books
  class RecordViewTest < ActiveSupport::TestCase
    setup do
      @book = books(:pragmatic)
    end

    test 'increments view count for a normal visit' do
      assert_difference -> { @book.reload.view_count }, 1 do
        RecordView.call(@book)
      end

      assert_equal 0, @book.nfc_view_count
    end

    test 'increments view and nfc counts for nfc utm source' do
      assert_difference -> { @book.reload.view_count }, 1 do
        assert_difference -> { @book.reload.nfc_view_count }, 1 do
          RecordView.call(@book, utm_source: 'nfc')
        end
      end
    end

    test 'nfc_visit detects nfc utm source only' do
      assert RecordView.nfc_visit?('nfc')
      assert_not RecordView.nfc_visit?('email')
      assert_not RecordView.nfc_visit?(nil)
    end
  end
end
