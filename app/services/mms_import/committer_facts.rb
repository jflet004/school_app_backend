# app/services/mms_import/committer_facts.rb
module MmsImport
  class CommitterFacts
    Result = Struct.new(:facts, :skipped, :errors, keyword_init: true)

    def self.commit(io_path, import_batch_id)
      rows = Parser.preview(io_path, limit: nil)[:rows] # full file
      res = Result.new(facts: 0, skipped: 0, errors: [])

      rows.each_with_index do |row, i|
        begin
          teacher = (row["Teacher"] || "").to_s.strip
          date_s  = (row["Date"]    || "").to_s.strip
          time_s  = (row["Time"]    || "").to_s.strip
          room    = (row["Location"]|| row["Room"] || "").to_s.strip
          course  = (row["Event"]   || row["Course"] || "").to_s.strip
          student = (row["Student"] || "").to_s.strip
          att_raw = (row["Attendance"] || "").to_s.strip

          # skip incomplete lines
          if teacher.empty? || date_s.empty? || course.empty? || student.empty?
            res.skipped += 1
            next
          end

          on_date = parse_date(date_s) || (raise "Unparsable date #{date_s.inspect}")
          start_hhmm, end_hhmm = parse_time_range(time_s, on_date)

          status = normalize_attendance(att_raw)

          # Natural key for a session row:
key = {
  teacher_name: teacher,
  student_name: student,
  course_name:  course,
  on_date:      on_date,
  start_time:   start_hhmm,
  end_time:     end_hhmm,
  room:         room
}

fact = ImportFact.find_or_initialize_by(key)

if fact.new_record?
  # First time we see this row anywhere → insert
  fact.import_batch_id   = import_batch_id
  fact.attendance_status = ImportFact.attendance_statuses[status]
  fact.raw               = row
  fact.save!
  res.facts += 1
else
  # Already exists (maybe from a previous batch) → update in place if changed
  new_status = ImportFact.attendance_statuses[status]
  changed = false

  if fact.attendance_status_before_type_cast != new_status
    fact.attendance_status = new_status
    changed = true
  end
  if fact.import_batch_id != import_batch_id
    fact.import_batch_id = import_batch_id   # record the last batch that touched it
    changed = true
  end
  if fact.raw != row
    fact.raw = row
    changed = true
  end

  fact.save! if changed
  res.skipped += 1
end

        rescue => e
          res.errors << "Row #{i + 1}: #{e.message}"
        end
      end

      res
    end

    # --- helpers (same logic we used earlier) ---
def self.parse_date(val)
  return val if val.is_a?(Date)

  # Excel serial number (Roo sometimes surfaces numerics)
  if val.is_a?(Numeric)
    # Excel 1900 system: day 1 = 1899-12-31, but there’s the 1900 leap bug;
    # Roo uses 1899-12-30 baseline effectively for serial -> Date.
    return Date.new(1899, 12, 30) + val.to_i
  end

  s = val.to_s.strip
  return nil if s.empty?

  # Clean junk: NBSP/zero-width/RTL marks, *, quotes, etc.; keep digits and / -
  s = s.tr("\u00A0\u200B\u200E\u200F", "")
       .gsub(/[^\d\/\-]/, "") # "7/17/2025*" -> "7/17/2025"

  # Try m/d/yyyy or m-d-yyyy (also 2-digit year)
  begin
    if s.include?("/")
      m, d, y = s.split("/", 3).map(&:to_i)
    elsif s.include?("-")
      m, d, y = s.split("-", 3).map(&:to_i)
    end

    if m && d && y && m > 0 && d > 0
      y += (y >= 70 ? 1900 : 2000) if y < 100        # normalize 2-digit year
      return Date.new(y, m, d) rescue nil
    end
  rescue
    # fall through
  end

  # Last resort
  Date.parse(s) rescue nil
end


    def self.parse_time_range(str, date)
      s = str.to_s.strip
      return [nil, nil] if s.empty?
      s = s.tr("–—", "-")
      parts = s.split("-").map(&:strip)
      return [nil, nil] unless parts.size == 2
      t1 = parse_one_time(parts[0], date)
      t2 = parse_one_time(parts[1], date, meridian_hint: parts[0])
      [t1&.strftime("%H:%M"), t2&.strftime("%H:%M")]
    end

    def self.parse_one_time(part, date, meridian_hint: nil)
      p = part.to_s.strip
      return nil if p.empty?
      low = p.downcase
      has_ampm = low.include?("am") || low.include?("pm")
      hint = meridian_hint.to_s.downcase
      hint_ampm = hint.include?("pm") ? "pm" : (hint.include?("am") ? "am" : nil)
      numeric = p.gsub(/[^0-9:]/, "")
      if numeric =~ /\A(\d{1,2})(?::?(\d{2}))?\z/
        hh = $1.to_i
        mm = ($2 || "00").to_i
        ampm = has_ampm ? (low.include?("pm") ? "pm" : "am") : hint_ampm
        if ampm == "pm" && hh < 12
          hh += 12
        elsif ampm == "am" && hh == 12
          hh = 0
        end
        return Time.new(date.year, date.month, date.day, hh, mm)
      end
      nil
    end

def self.normalize_attendance(v)
  s = v.to_s.downcase.strip
  return :unknown if s.empty?

  # collapse rich labels to 3 buckets
  return :present   if s.include?("present")      # "present", "present, late", etc.
  return :absent    if s.include?("absent")       # "absent, no make-up", "absent, notice given"
  return :unknown   if s.include?("unrecorded")   # treat as unrecorded bucket

  :unknown
end

  end
end
