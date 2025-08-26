require "roo"

module MMSImport
  class Parser
    def self.preview(io_path, limit: 50)
      xlsx = Roo::Spreadsheet.open(io_path, extension: :xlsx)
      sheet = xlsx.sheet(0)

      headers = sheet.row(1).map { |h| h.to_s.strip }
      rows = []
      # Start at row 2
      (2..[sheet.last_row, limit + 1].min).each do |r|
        raw = sheet.row(r)
        hash = headers.zip(raw).to_h
        rows << Transformers::MMS.transform(hash)
      end

      { columns: headers, rows: rows }
    end
  end
end
