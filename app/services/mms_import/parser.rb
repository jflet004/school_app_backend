require "roo"

# Reads an MMS Excel export and reproduces the output of the provided Apps Script:
# - Detect "teacher" rows: first cell present, all other cells empty
# - Detect header rows: col2 == "Date" && col3 == "Time"
# - Output rows: [Teacher, Date, Time, Location, Student, Event, Attendance, ...]
#
# Returns: { columns: [...], rows: [ {col=>val, ...}, ... ] }
module MmsImport
  class Parser
    DEFAULT_LIMIT = 50

    def self.preview(io_path, limit: DEFAULT_LIMIT, sheet_name: nil)
      xlsx  = Roo::Spreadsheet.open(io_path, extension: :xlsx)
      sheet =
        if sheet_name && xlsx.sheets.include?(sheet_name)
          xlsx.sheet(sheet_name)
        else
          # Use "Data" if present; otherwise first sheet (your sample is "Sheet 1")
          xlsx.sheets.include?("Data") ? xlsx.sheet("Data") : xlsx.sheet(0)
        end

      teacher = nil
      header_found = false
      header = []   # ["Teacher", "Date", "Time", ...]
      out_rows = []

      (1..sheet.last_row).each do |r|
        row = safe_row(sheet, r)

        # Normalize to simple Ruby values (String/Date/Time/Float/Integer/Nil)
        # row[0] is col A, row[1] col B, ...
        a0 = row[0]
        rest = row[1..-1] || []

        is_teacher_row = present?(a0) && rest.all? { |c| blank?(c) }
        is_header_row  = row[1].to_s.strip == "Date" && row[2].to_s.strip == "Time"

        if is_teacher_row
          teacher = a0.to_s.strip
        elsif is_header_row
          unless header_found
            header_found = true
            header = ["Teacher"] + rest.map { |h| h.to_s.strip }
          end
        elsif teacher && present?(row[1]) # data row under a teacher with a Date
          # Build a hash that aligns to the header columns
          h = {}
          h["Teacher"] = teacher
          rest.each_with_index do |val, idx|
            key = header[idx + 1] || "Col#{idx + 2}"
            h[key] = format_cell(val)
          end
          out_rows << h
        end

        break if limit && out_rows.size >= limit
      end

      # In case the header wasn't encountered (edge cases), synthesize a minimal one
      header = ["Teacher", "Date", "Time", "Location", "Student", "Event", "Attendance"] if header.empty?

      { columns: header, rows: out_rows }
    end

    # -------- helpers --------

    def self.safe_row(sheet, r)
      # Roo returns arrays sized to the last non-empty column; pad at least 7 cols
      row = sheet.row(r)
      target_len = [row.length, 7].max
      row += [nil] * (target_len - row.length)
    end

    def self.present?(v)
      !blank?(v)
    end

    def self.blank?(v)
      v.nil? || (v.is_a?(String) && v.strip.empty?)
    end

    def self.format_cell(v)
      case v
      when Date, DateTime, Time
        # ISO-ish so FE can parse (you can tweak later)
        v.to_s
      else
        v
      end
    end
  end
end
