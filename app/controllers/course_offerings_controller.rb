# app/controllers/course_offerings_controller.rb
class CourseOfferingsController < ApplicationController
  before_action :set_teacher, only: [:index, :create]
  before_action :set_offering, only: [:show, :update, :destroy]

  # GET /course_offerings
  # GET /teachers/:teacher_id/course_offerings
  #
  # Params (all optional):
  #   page, per_page
  #   course_id, teacher_id, day_of_week
  #   q (search: course name, teacher name, room)
  #   sort: created_at|course_name|teacher_name|day_of_week|start_time
  #   direction: asc|desc
  def index
    scope = @teacher ? @teacher.course_offerings : CourseOffering.all

    # Eager load
    scope = scope.includes(:course, :teacher)

    # Filters
    scope = scope.where(course_id: params[:course_id]) if params[:course_id].present?
    scope = scope.where(teacher_id: params[:teacher_id]) if params[:teacher_id].present?
    scope = scope.where(day_of_week: params[:day_of_week]) if params[:day_of_week].present?

    if params[:q].present?
      q = "%#{CourseOffering.sanitize_sql_like(params[:q])}%"
      scope = scope.joins(:course).left_joins(:teacher)
                   .where(
                     "courses.name LIKE :q OR course_offerings.room LIKE :q OR "\
                     "teachers.first_name LIKE :q OR teachers.last_name LIKE :q", q: q
                   )
    end

    # Sorting
    sort      = params[:sort].presence_in(%w[created_at course_name teacher_name day_of_week start_time]) || "created_at"
    direction = params[:direction].to_s.downcase == "asc" ? "ASC" : "DESC"
    scope = case sort
            when "course_name"
              scope.joins(:course).order("courses.name #{direction}, course_offerings.id ASC")
            when "teacher_name"
              scope.joins(:teacher).order("teachers.last_name #{direction}, teachers.first_name #{direction}, course_offerings.id ASC")
            when "day_of_week"
              scope.order("course_offerings.day_of_week #{direction}, course_offerings.start_time #{direction}, course_offerings.id ASC")
            when "start_time"
              scope.order("course_offerings.start_time #{direction}, course_offerings.id ASC")
            else
              scope.order("course_offerings.created_at #{direction}, course_offerings.id ASC")
            end

    # Pagination
    page     = params.fetch(:page, 1).to_i
    per_page = [[params.fetch(:per_page, 20).to_i, 1].max, 100].min
    total       = scope.count
    total_pages = (total / per_page.to_f).ceil
    offset      = (page - 1) * per_page
    offerings   = scope.offset(offset).limit(per_page)

    render json: {
      data: offerings.as_json(
        include: {
          course:  { only: [:id, :name, :course_type, :price_cents] },
          teacher: { only: [:id, :first_name, :last_name] }
        }
      ),
      meta: { page: page, per_page: per_page, total: total, total_pages: total_pages }
    }
  end

  # GET /course_offerings/:id
  # GET /teachers/:teacher_id/course_offerings/:id
def show
  off = @offering.as_json(include: { course: {}, teacher: {} })
  off[:enrollments_count] = @offering.enrollments.count
  render json: off
end


  # POST /teachers/:teacher_id/course_offerings
  # (or top-level with :teacher_id in params)
  def create
    offering =
      if @teacher
        @teacher.course_offerings.build(offering_params.except(:teacher_id))
      else
        CourseOffering.new(offering_params) # expects :teacher_id present
      end

    if offering.save
      render json: offering.as_json(include: [:course, :teacher]), status: :created
    else
      render json: { errors: offering.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /course_offerings/:id
  # (We allow reassigning teacher/course if needed)
  def update
    if @offering.update(offering_params)
      render json: @offering.as_json(include: [:course, :teacher])
    else
      render json: { errors: @offering.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /course_offerings/:id
  def destroy
    @offering.destroy
    head :no_content
  end

  private

  def set_teacher
    @teacher = Teacher.find_by(id: params[:teacher_id]) if params[:teacher_id]
  end

  def set_offering
    @offering = if params[:teacher_id]
                  Teacher.find(params[:teacher_id]).course_offerings.find(params[:id])
                else
                  CourseOffering.find(params[:id])
                end
  end

  def offering_params
    params.require(:course_offering).permit(
      :course_id, :teacher_id,
      :day_of_week, :start_time, :end_time, :room,
      :location, :capacity, :notes
    )
  end
end
