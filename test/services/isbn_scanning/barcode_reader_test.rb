require 'test_helper'

module IsbnScanning
  class BarcodeReaderTest < ActiveSupport::TestCase
    test 'extracts valid isbn barcodes from zbar output' do
      reader = IsbnScanning::BarcodeReader.new(nil)
      output = "9780201616224\nnot-an-isbn\n9780132350884\n"

      assert_equal %w[9780201616224 9780132350884], reader.send(:parse_barcodes, output)
    end

    test 'returns empty array for non-image uploads without raising' do
      uploaded = uploaded_file('scan.jpg', 'image/jpeg', 'binary')

      assert_equal [], IsbnScanning::BarcodeReader.call(uploaded)
    end

    private

    def uploaded_file(name, type, content)
      file = Tempfile.new(name)
      file.write(content)
      file.rewind
      ActionDispatch::Http::UploadedFile.new(filename: name, type: type, tempfile: file)
    end
  end
end
