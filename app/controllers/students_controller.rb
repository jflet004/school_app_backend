class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :update, :destroy]

def index
  # Params (all optional):
  # page, per_page, q, student_type, gender, ethnicity, experience_years, heard_about, sort, direction
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

  # Sorting
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
    meta: {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: total_pages
    }
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

  private

  def set_student
    @student = Student.find(params[:id])
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
