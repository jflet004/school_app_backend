# app/controllers/students_controller.rb
require "csv"

class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :update, :destroy]

  def index
    # Params (all optional):
    # page, per_page, q, student_type, gender, ethnicity, experience_years,
    # heard_about, sort, direction
    page      = params.fetch(:page, 1).to_i
    per_page  = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min # cap at 100
    sort      = params[:sort].presence_in(%w[created_at name]) || "created_at"
    direction = params[:direction].to_s.downcase == "asc" ? :asc : :desc

    scope = Student.includes(:parent_contacts)
                   .search(params[:q])
                   .filter_student_type(params[:student_type])
                   .filter_gender(params[:gender])
                   .filter_ethnicity(params[:ethnicity])
                   .filter_experience(params[:experience_years])
                   .filter_heard_about(params[:heard_about])

    scope = if sort == "name"
              scope.order(last_name: direction, first_name: direction, id: :asc)
            else
              scope.order(created_at: direction, id: :asc)
            end

    total       = scope.count
    total_pages = (total / per_page.to_f).ceil
    offset      = (page - 1) * per_page
    students    = scope.offset(offset).limit(per_page)

    render json: {
      data: students.as_json(include: :parent_contacts),
      meta: { page:, per_page:, total:, total_pages: }
    }
  end

  def show
    render json: @student.as_json(include: :parent_contacts)
  end

  def create
    student = Student.new(student_params)
    if student.save
      render json: student.as_json(include: :parent_contacts), status: :created
    else
      render json: { errors: student.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @student.update(student_params)
      render json: @student.as_json(include: :parent_contacts)
    else
      render json: { errors: @student.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    @student.destroy
    head :no_content
  end

  # ⬇⬇ KEEP EXPORT **ABOVE** `private` so it’s a PUBLIC action
  # GET /students/export.csv
  # GET /students/export.xlsx
  def export
    scope = filtered_sorted_scope # all matches (no pagination)

    respond_to do |format|
      format.csv do
        csv = CSV.generate(headers: true) do |out|
          out << csv_headers
          scope.find_each(batch_size: 1000) { |s| out << csv_row_for(s) }
        end
        send_data csv,
                  filename: "students-#{Time.current.strftime("%Y%m%d-%H%M%S")}.csv",
                  type: "text/csv"
      end

      format.xlsx do
        # caxlsx provides Axlsx::
        pkg = Axlsx::Package.new
        wb = pkg.workbook
        wb.add_worksheet(name: "Students") do |sheet|
          sheet.add_row csv_headers
          scope.find_each(batch_size: 1000) { |s| sheet.add_row csv_row_for(s) }
        end
        send_data pkg.to_stream.read,
                  filename: "students-#{Time.current.strftime("%Y%m%d-%H%M%S")}.xlsx",
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      end

      format.any { render json: { error: "Unsupported format" }, status: :not_acceptable }
    end
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  # Reuse the same filters/sorting as index (but no pagination)
  def filtered_sorted_scope
    scope = Student.includes(:parent_contacts)
                   .search(params[:q])
                   .filter_student_type(params[:student_type])
                   .filter_gender(params[:gender])
                   .filter_ethnicity(params[:ethnicity])
                   .filter_experience(params[:experience_years])
                   .filter_heard_about(params[:heard_about])

    sort      = params[:sort].presence_in(%w[created_at name]) || "created_at"
    direction = params[:direction].to_s.downcase == "asc" ? :asc : :desc

    if sort == "name"
      scope.order(last_name: direction, first_name: direction, id: :asc)
    else
      scope.order(created_at: direction, id: :asc)
    end
  end

  def csv_headers
    [
      "ID","Type","First Name","Last Name","Birthday","Instrument","Gender","Experience",
      "Ethnicity","Email","Phone","Address","City","State","Postal Code",
      "Household Size","Household Income","Heard About",
      "Current School (child)","School Offers Arts","Parent Contacts"
    ]
  end

  def csv_row_for(s)
    parents_summary = s.parent_contacts.map { |p|
      "#{p.parent_first_name} #{p.parent_last_name} (#{p.email || 'no-email'})"
    }.join("; ")

    [
      s.id, s.student_type, s.first_name, s.last_name, s.birthday&.to_s,
      s.instrument_preference, s.gender, s.experience_years, s.ethnicity,
      s.email, s.phone_number, s.home_address, s.city, s.state, s.postal_code,
      s.household_size, s.household_income, s.heard_about,
      s.current_school_name,
      (s.current_school_offers_arts.nil? ? nil : s.current_school_offers_arts ? "Yes" : "No"),
      parents_summary
    ]
  end

  # Allow nested parent_contacts on create/update
  def student_params
    params.require(:student).permit(
      :student_type,
      :first_name, :last_name, :birthday, :instrument_preference,
      :gender, :experience_years, :ethnicity,
      :email, :phone_number, :home_address, :city, :state, :postal_code,
      :household_size, :household_income, :heard_about,
      :current_school_name, :current_school_offers_arts,
      parent_contacts_attributes: [
        :id, :parent_first_name, :parent_last_name, :email, :phone_number,
        :home_address, :city, :state, :postal_code, :_destroy
      ]
    )
  end
end
