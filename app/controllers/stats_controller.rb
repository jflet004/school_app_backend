# app/controllers/stats_controller.rb
class StatsController < ApplicationController
  # GET /stats/attendance?from=2025-07-01&to=2025-12-31&fy_start=8&teacher=Nguyen&course=Beginner%20Piano
  def attendance
    from     = params[:from].present? ? Date.parse(params[:from]) : ImportFact.minimum(:on_date)
    to       = params[:to].present?   ? Date.parse(params[:to])   : ImportFact.maximum(:on_date)
    fy_start = params[:fy_start].presence&.to_i || 8 # August default

    if from.nil? || to.nil?
      return render json: {
        series: [],
        totals: { period: nil, sessions: 0, present: 0, absent: 0, unknown: 0 },
        fiscal_years: {},
        quarters: {},
        params: { from:, to:, fy_start: fy_start }
     }
    end

    return render json: { series: [], total: { sessions: 0 } } unless from && to

    scope = ImportFact.where(on_date: from..to)
    scope = scope.where("teacher_name LIKE ?", "%#{params[:teacher]}%") if params[:teacher].present?
    scope = scope.where("course_name  LIKE ?", "%#{params[:course]}%")  if params[:course].present?

    # SQLite strftime('%Y-%m', on_date) -> "2025-07"
    month_key = Arel.sql("strftime('%Y-%m', on_date) AS period")

  present_cnt = Arel.sql("SUM(CASE WHEN attendance_status = 0 THEN 1 ELSE 0 END) AS present")
  absent_cnt  = Arel.sql("SUM(CASE WHEN attendance_status IN (1,2) THEN 1 ELSE 0 END) AS absent")  # include excused if ever used
  unknown_cnt = Arel.sql("SUM(CASE WHEN attendance_status = 3 THEN 1 ELSE 0 END) AS unknown")
  total_cnt   = Arel.sql("COUNT(*) AS sessions")


  rows = scope
    .select(month_key, present_cnt, absent_cnt, unknown_cnt, total_cnt)
    .group("strftime('%Y-%m', on_date)")
    .order("period ASC")

  series = rows.map do |r|
    { period: r.period, sessions: r.sessions.to_i,
      present: r.present.to_i, absent: r.absent.to_i, unknown: r.unknown.to_i }    end

def fiscal_quarter_for(year, month, fy_start)
  # Map months to 0..11 where fy_start == 0
  offset = (month - fy_start) % 12
  qnum   = (offset / 3) + 1 # 1..4
  fy     = month >= fy_start ? year : year - 1
  [fy, qnum]
end

# --- aggregate by fiscal quarter ---
quarters = Hash.new { |h, k|
  h[k] = { sessions: 0, present: 0, absent: 0, unknown: 0 }
}

series.each do |r|
  y, m = r[:period].split("-").map(&:to_i) # "YYYY-MM"
  fy, q = fiscal_quarter_for(y, m, fy_start.to_i)
  key = "FY#{fy}-Q#{q}"
  agg = quarters[key]
  agg[:sessions] += r[:sessions]
  agg[:present]  += r[:present]
  agg[:absent]   += r[:absent]
  agg[:unknown]  += r[:unknown]
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
        unknown:  arr.sum { _1[:unknown]  }
      }
    }

    render json: {
      series: series,
      totals: {
        sessions: series.sum { _1[:sessions] },
        present:  series.sum { _1[:present]  },
        absent:   series.sum { _1[:absent]   },
        unknown:  series.sum { _1[:unknown]  }
      },
      fiscal_years: fy,
      quarters: quarters,
      params: { from:, to:, fy_start: fy_start }
    }
  end
end
