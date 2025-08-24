class TeachersController < ApplicationController
  before_action :set_teacher, only: [:show, :update, :destroy]

  # GET /teachers
  # Params: page, per_page, q, sort(name|created_at), direction(asc|desc)
  def index
    page      = params.fetch(:page, 1).to_i
    per_page  = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
    sort      = params[:sort].presence_in(%w[created_at name]) || "created_at"
    direction = params[:direction].to_s.downcase == "asc" ? :asc : :desc

    scope = Teacher.includes(:courses).search(params[:q])

    scope = if sort == "name"
              scope.order(last_name: direction, first_name: direction, id: :asc)
            else
              scope.order(created_at: direction, id: :asc)
            end

    total       = scope.count
    total_pages = (total / per_page.to_f).ceil
    offset      = (page - 1) * per_page
    teachers    = scope.offset(offset).limit(per_page)

    render json: {
      data: teachers.as_json(include: :courses),
      meta: { page: page, per_page: per_page, total: total, total_pages: total_pages }
    }
  end

  # GET /teachers/:id
  def show
    render json: @teacher.as_json(include: :courses)
  end

  # POST /teachers
  def create
    teacher = Teacher.new(teacher_params)
    if teacher.save
      render json: teacher.as_json(include: :courses), status: :created
    else
      render json: { errors: teacher.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /teachers/:id
  def update
    if @teacher.update(teacher_params)
      render json: @teacher.as_json(include: :courses)
    else
      render json: { errors: @teacher.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /teachers/:id
  def destroy
    @teacher.destroy
    head :no_content
  end

  private

  def set_teacher
    @teacher = Teacher.find(params[:id])
  end

  def teacher_params
    params.require(:teacher).permit(
      :first_name, :last_name, :email, :phone_number, :hire_date, :base_rate
    )
  end
end
