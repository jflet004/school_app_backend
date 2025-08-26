class CoursesController < ApplicationController
  before_action :set_course, only: [:show, :update, :destroy]

  # GET /courses
  # Params: page, per_page, q, sort(name|created_at), direction(asc|desc), active(true|false)
  def index
    page      = params.fetch(:page, 1).to_i
    per_page  = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
    sort      = params[:sort].presence_in(%w[created_at name]) || "created_at"
    direction = params[:direction].to_s.downcase == "asc" ? :asc : :desc

    scope = Course.all
    scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
    if params[:q].present?
      q = "%#{Course.sanitize_sql_like(params[:q])}%"
      scope = scope.where("name LIKE ?", q)
    end

    scope = (sort == "name") ? scope.order(name: direction, id: :asc) : scope.order(created_at: direction, id: :asc)

    total       = scope.count
    total_pages = (total / per_page.to_f).ceil
    offset      = (page - 1) * per_page
    courses     = scope.offset(offset).limit(per_page)

    render json: {
      data: courses.as_json(only: [:id, :name, :course_type, :price_cents, :active, :created_at, :updated_at]),
      meta: { page:, per_page:, total:, total_pages: }
    }
  end

  # GET /courses/:id
  def show
    render json: @course.as_json(include: { course_offerings: { include: :teacher } })
  end

  # POST /courses
  def create
    course = Course.new(course_params)
    if course.save
      render json: course, status: :created
    else
      render json: { errors: course.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /courses/:id
  def update
    if @course.update(course_params)
      render json: @course
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /courses/:id
  def destroy
    @course.destroy
    head :no_content
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name, :course_type, :price_cents, :active)
  end
end
