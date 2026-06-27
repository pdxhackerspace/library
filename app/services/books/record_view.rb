module Books
  class RecordView
    NFC_UTM_SOURCE = 'nfc'.freeze

    def self.call(book, utm_source: nil)
      new(book, utm_source:).call
    end

    def self.nfc_visit?(utm_source)
      utm_source.to_s == NFC_UTM_SOURCE
    end

    def initialize(book, utm_source: nil)
      @book = book
      @utm_source = utm_source
    end

    def call
      if nfc_visit?
        # rubocop:disable Rails/SkipsModelValidations -- counter columns only
        Book.update_counters(@book.id, view_count: 1, nfc_view_count: 1)
        # rubocop:enable Rails/SkipsModelValidations
      else
        # rubocop:disable Rails/SkipsModelValidations -- counter columns only
        Book.update_counters(@book.id, view_count: 1)
        # rubocop:enable Rails/SkipsModelValidations
      end
      @book.reload
    end

    def nfc_visit?
      self.class.nfc_visit?(@utm_source)
    end
  end
end
