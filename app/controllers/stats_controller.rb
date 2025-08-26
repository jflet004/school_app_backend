# app/controllers/stats_controller.rb
class StatsController < ApplicationController
  # GET /stats/attendance?from=2025-07-01&to=2025-12-31&fy_start=8&teacher=Nguyen&course=Beginner%20Piano
  def attendance
    from     = params[:from].present? ? Date.parse(params[:from]) : ImportFact.minimum(:on_date)
    to       = params[:to].present?   ? Date.parse(params[:to])   : ImportFact.maximum(:on_date)
    fy_start = params[:fy_start].presence&.to_i || 8 # August default

    return render json: { series: [], total: { sessions: 0 } } unless from && to

    scope = ImportFact.where(on_date: from..to)
    scope = scope.where("teacher_name LIKE ?", "%#{params[:teacher]}%") if params[:teacher].present?
    scope = scope.where("course_name  LIKE ?", "%#{params[:course]}%")  if params[:course].present?

    # SQLite strftime('%Y-%m', on_date) -> "2025-07"
    month_key = Arel.sql("strftime('%Y-%m', on_date) AS period")

    present_cnt = Arel.sql("SUM(CASE WHEN attendance_status = 0 THEN 1 ELSE 0 END) AS present")
    absent_cnt  = Arel.sql("SUM(CASE WHEN attendance_status = 1 THEN 1 ELSE 0 END) AS absent")
    excused_cnt = Arel.sql("SUM(CASE WHEN attendance_status = 2 THEN 1 ELSE 0 END) AS excused")
    unknown_cnt = Arel.sql("SUM(CASE WHEN attendance_status = 3 THEN 1 ELSE 0 END) AS unknown")
    total_cnt   = Arel.sql("COUNT(*) AS sessions")

    rows = scope
      .select(month_key, present_cnt, absent_cnt, excused_cnt, unknown_cnt, total_cnt)
      .group("strftime('%Y-%m', on_date)")
      .order("period ASC")

    series = rows.map do |r|
      { period: r.period, sessions: r.sessions.to_i,
        present: r.present.to_i, absent: r.absent.to_i,
        excused: r.excused.to_i, unknown: r.unknown.to_i }
    end

    # Quick fiscal-year buckets (Aug–Jul by default)
    fy = series.group_by { |r|
      y, m = r[:period].split("-").map(&:to_i)
      fy_year = (m >= fy_start) ? y : (y - 1)
      "FY#{fy_year}-#{(fy_year + 1).to_s[-2,2]}"
    }.transform_values { |arr|
      {
        sessions: arr.sum { _1[:sessions] },
        present:  arr.sum { _1[:present]  },
        absent:   arr.sum { _1[:absent]   },
        excused:  arr.sum { _1[:excused]  },
        unknown:  arr.sum { _1[:unknown]  }
      }
    }

    render json: {
      series: series,
      totals: {
        sessions: series.sum { _1[:sessions] },
        present:  series.sum { _1[:present]  },
        absent:   series.sum { _1[:absent]   },
        excused:  series.sum { _1[:excused]  },
        unknown:  series.sum { _1[:unknown]  }
      },
      fiscal_years: fy,
      params: { from:, to:, fy_start: fy_start }
    }
  end
end
