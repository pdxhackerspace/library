require 'test_helper'
require 'open3'

class NfcNdefWriteRecordsTest < ActiveSupport::TestCase
  test 'ndef write records meet Web NFC mime payload requirements' do
    script = Rails.root.join('test/javascript/nfc_ndef_write_records_test.mjs')
    stdout, stderr, status = Open3.capture3('node', '--test', script.to_s)

    assert status.success?, [stdout, stderr].join("\n")
  end
end
