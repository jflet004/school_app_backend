# app/controllers/enrollments_controller.rb
class EnrollmentsController < ApplicationController
  before_action :set_course_offering, only: [:index, :create]
  before_action :set_enrollment, only: [:show, :update, :destroy, :charge]

  # GET /course_offerings/:course_offering_id/enrollments
  # Optional: status filter
  def index
    scope = @course_offering.enrollments.includes(:student).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    render json: scope.as_json(include: { student: { only: [:id, :first_name, :last_name, :email] } })
  end

  # POST /course_offerings/:course_offering_id/enrollments
  # Body: { enrollment: { student_id, status?, started_on?, monthly_rate_cents? } }
def create
    enrollment = nil

    Enrollment.transaction do
      # Lock the offering row to serialize capacity checks
      @course_offering.lock!

      if @course_offering.capacity.present? &&
         @course_offering.enrollments.active.count >= @course_offering.capacity
        render json: { errors: ["This class is full (capacity #{@course_offering.capacity})."] },
               status: :unprocessable_content and return
      end

      enrollment = @course_offering.enrollments.new(enrollment_params)

      unless enrollment.save
        render json: { errors: enrollment.errors.full_messages },
               status: :unprocessable_content and return
      end
    end

    render json: enrollment.as_json(include: :student), status: :created
  end

  # GET /enrollments/:id
  def show
    render json: @enrollment.as_json(include: { course_offering: { include: :course }, student: {} })
  end

  # PATCH/PUT /enrollments/:id
  def update
    if @enrollment.update(enrollment_params)
      render json: @enrollment
    else
      render json: { errors: @enrollment.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /enrollments/:id
  def destroy
    @enrollment.destroy
    head :no_content
  end

  # GET /enrollments/:id/charge?year=2025&month=9
  def charge
    year  = params[:year].to_i
    month = params[:month].to_i
    unless (1900..2100).cover?(year) && (1..12).cover?(month)
      return render json: { error: "year and month are required (e.g., ?year=2025&month=9)" }, status: :bad_request
    end

    cents = @enrollment.charge_cents_for(year: year, month: month)
    render json: {
      enrollment_id: @enrollment.id,
      year: year, month: month,
      per_class_cents: (@enrollment.monthly_rate_cents || @enrollment.course_offering.course.price_cents),
      occurrences: @enrollment.course_offering.occurrences_in_month(year, month),
      total_cents: cents,
      total_formatted: format("$%.2f", cents / 100.0)
    }
  end

  private

  def set_course_offering
    @course_offering = CourseOffering.find(params[:course_offering_id])
  end

  def set_enrollment
    @enrollment = Enrollment.find(params[:id])
  end

  def enrollment_params
    params.require(:enrollment).permit(:student_id, :status, :started_on, :ended_on, :monthly_rate_cents, :notes)
  end
end
