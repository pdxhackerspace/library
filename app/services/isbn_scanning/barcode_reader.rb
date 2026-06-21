require 'open3'
require 'tempfile'

module IsbnScanning
  class BarcodeReader
    def self.call(uploaded_file)
      new(uploaded_file).call
    end

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
    end

    def call
      return [] unless zbarimg_available?

      Tempfile.create(['isbn-scan', extension]) do |temp|
        temp.binmode
        temp.write(@uploaded_file.read)
        temp.flush

        scan_file(temp.path)
      end
    end

    private

    def extension
      filename = @uploaded_file.respond_to?(:original_filename) ? @uploaded_file.original_filename.to_s : ''
      ext = File.extname(filename)
      ext.presence || '.jpg'
    end

    def zbarimg_available?
      _, _, status = Open3.capture3('which', 'zbarimg')
      status.success?
    end

    def scan_file(path)
      stdout, _, status = Open3.capture3('zbarimg', '--quiet', '--raw', path)
      return [] unless status.success?

      parse_barcodes(stdout)
    end

    def parse_barcodes(output)
      output.lines.filter_map do |line|
        code = IsbnCode.normalize(line.strip)
        code if IsbnCode.valid?(code)
      end.uniq
    end
  end
end
