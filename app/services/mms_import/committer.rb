require "roo"

module MmsImport
  class Committer
    Result = Struct.new(:courses, :teachers, :offerings, :students, :enrollments, :attendance, :skipped, :errors, keyword_init: true)

    def self.commit(io_path)
      rows = Parser.preview(io_path, limit: nil)[:rows] # reuse the same “Apps Script” flattening
      tally = Result.new(courses: 0, teachers: 0, offerings: 0, students: 0, enrollments: 0, attendance: 0, skipped: 0, errors: [])

      rows.each_with_index do |row, i|
        begin
          teacher_name = (row["Teacher"] || "").to_s.strip
          date_str     = (row["Date"]    || "").to_s.strip
          time_str     = (row["Time"]    || "").to_s.strip
          course_name  = (row["Event"]   || row["Course"] || "").to_s.strip
          location     = (row["Location"]|| row["Room"]   || "").to_s.strip
          student_name = (row["Student"] || "").to_s.strip
          attendance   = (row["Attendance"] || "").to_s.strip

          # Skip incomplete rows
          if student_name.empty? || course_name.empty? || date_str.empty?
            tally.skipped += 1
            next
          end

          on_date = parse_date(date_str) || (raise "Unparsable date: #{date_str.inspect}")
          dow     = %w[sunday monday tuesday wednesday thursday friday saturday][on_date.wday].to_sym
          start_hhmm, end_hhmm = parse_time_range(time_str, on_date) # may return [nil, nil]

          # --- upserts ---

          course = Course.find_or_create_by!(name: course_name)
          tally.courses += 1 if course.previous_changes.key?("id")

          t_first, t_last = split_name(teacher_name)
          teacher = Teacher.find_or_create_by!(first_name: t_first, last_name: t_last)
          tally.teachers += 1 if teacher.previous_changes.key?("id")

          offering = CourseOffering.find_or_initialize_by(
            course_id: course.id,
            teacher_id: teacher.id,
            day_of_week: dow
          )
          # Only set times/room if present
          offering.start_time = start_hhmm if start_hhmm
          offering.end_time   = end_hhmm   if end_hhmm
          offering.room       = location   unless location.empty?
          offering.save!
          tally.offerings += 1 if offering.previous_changes.key?("id")

          s_first, s_last = split_name(student_name)
          student = Student.find_or_create_by!(first_name: s_first, last_name: s_last) do |s|
            s.student_type = :adult # we don't know age from MMS; adjust later if needed
          end
          tally.students += 1 if student.previous_changes.key?("id")

          enrollment = Enrollment.find_or_create_by!(student_id: student.id, course_offering_id: offering.id) do |e|
            e.status = :active
          end
          tally.enrollments += 1 if enrollment.previous_changes.key?("id")

          status = normalize_attendance(attendance)
          ae = AttendanceEvent.find_or_initialize_by(student_id: student.id, course_offering_id: offering.id, on_date: on_date)
          ae.status   = status
          ae.raw_time = time_str
          if ae.changed?
            ae.save!
            tally.attendance += 1
          end

        rescue => ex
          tally.errors << "Row #{i + 1}: #{ex.message}"
        end
      end

      tally
    end

    # ------------ helpers ------------

    def self.split_name(name)
      n = name.to_s.strip
      return ["", ""] if n.empty?
      if n.include?(",")
        last, first = n.split(",", 2).map { |s| s.strip }
        [first, last]
      else
        parts = n.split(/\s+/)
        first = parts.first
        last  = parts[1..]&.join(" ") || ""
        [first, last]
      end
    end

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


    # Accepts "15:00–16:00", "3:00-4:00 PM", "1500-1600", etc. Returns ["HH:MM","HH:MM"] or [nil,nil].
    def self.parse_time_range(str, date)
      s = str.to_s.strip
      return [nil, nil] if s.empty?
      s = s.tr("–—", "-")
      parts = s.split("-").map(&:strip)
      return [nil, nil] unless parts.size == 2
      t1 = parse_one_time(parts[0], date)
      t2 = parse_one_time(parts[1], date, meridian_hint: parts[0])
      hh1 = t1&.strftime("%H:%M")
      hh2 = t2&.strftime("%H:%M")
      [hh1, hh2]
    end

    def self.parse_one_time(part, date, meridian_hint: nil)
      p = part.to_s.strip
      return nil if p.empty?
      low = p.downcase
      has_ampm = low.include?("am") || low.include?("pm")
      hint = meridian_hint.to_s.downcase
      hint_ampm = if hint.include?("pm")
                    "pm"
                  elsif hint.include?("am")
                    "am"
                  else
                    nil
                  end
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

    def self.normalize_attendance(val)
      v = val.to_s.strip.downcase
      case v
      when "present", "p", "attended", "yes", "y" then :present
      when "absent", "a", "no", "n", "missed"     then :absent
      when "excused", "e"                         then :excused
      else :unknown
      end
    end
  end
end
