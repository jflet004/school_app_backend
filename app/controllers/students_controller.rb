class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :update, :destroy]

  def index
    students = Student.includes(:parent_contacts).order(created_at: :desc)
    render json: students.as_json(include: :parent_contacts)
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
