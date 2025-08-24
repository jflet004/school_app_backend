class CoursesController < ApplicationController
  before_action :set_teacher
  before_action :set_course, only: [:show, :update, :destroy]

  # GET /teachers/:teacher_id/courses
  def index
    render json: @teacher.courses.order(created_at: :desc)
  end

  # GET /teachers/:teacher_id/courses/:id
  def show
    render json: @course
  end

  # POST /teachers/:teacher_id/courses
  def create
    course = @teacher.courses.build(course_params)
    if course.save
      render json: course, status: :created
    else
      render json: { errors: course.errors.full_messages }, status: :unprocessable_content
    end
  end

  # PATCH/PUT /teachers/:teacher_id/courses/:id
  def update
    if @course.update(course_params)
      render json: @course
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /teachers/:teacher_id/courses/:id
  def destroy
    @course.destroy
    head :no_content
  end

  private

  def set_teacher
    @teacher = Teacher.find(params[:teacher_id])
  end

  def set_course
    @course = @teacher.courses.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name)
  end
end
