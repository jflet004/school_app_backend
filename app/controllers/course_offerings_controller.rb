class CourseOfferingsController < ApplicationController
  before_action :set_teacher
  before_action :set_offering, only: [:show, :update, :destroy]

  # GET /teachers/:teacher_id/course_offerings
  def index
    render json: @teacher.course_offerings.includes(:course).order(created_at: :desc)
                        .as_json(include: :course)
  end

  # GET /teachers/:teacher_id/course_offerings/:id
  def show
    render json: @offering.as_json(include: :course)
  end

  # POST /teachers/:teacher_id/course_offerings
  def create
    offering = @teacher.course_offerings.build(offering_params)
    if offering.save
      render json: offering.as_json(include: :course), status: :created
    else
      render json: { errors: offering.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /teachers/:teacher_id/course_offerings/:id
  def update
    if @offering.update(offering_params)
      render json: @offering.as_json(include: :course)
    else
      render json: { errors: @offering.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /teachers/:teacher_id/course_offerings/:id
  def destroy
    @offering.destroy
    head :no_content
  end

  private

  def set_teacher
    @teacher = Teacher.find(params[:teacher_id])
  end

  def set_offering
    @offering = @teacher.course_offerings.find(params[:id])
  end

  def offering_params
    params.require(:course_offering).permit(
      :course_id, :day_of_week, :start_time, :end_time, :room,
      # keep any extra columns you added earlier during the prototype phase:
      :location, :capacity, :notes
    )
  end
end
