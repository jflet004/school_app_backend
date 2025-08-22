class ParentContactsController < ApplicationController
  before_action :set_student
  before_action :set_parent_contact, only: [:show, :update, :destroy]

  def index
    render json: @student.parent_contacts
  end

  def show
    render json: @parent_contact
  end

  def create
    contact = @student.parent_contacts.new(parent_contact_params)
    if contact.save
      render json: contact, status: :created
    else
      render json: { errors: contact.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @parent_contact.update(parent_contact_params)
      render json: @parent_contact
    else
      render json: { errors: @parent_contact.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    @parent_contact.destroy
    head :no_content
  end

  private

  def set_student
    @student = Student.find(params[:student_id])
  end

  def set_parent_contact
    @parent_contact = @student.parent_contacts.find(params[:id])
  end

  def parent_contact_params
    params.require(:parent_contact).permit(
      :parent_first_name, :parent_last_name, :email, :phone_number,
      :home_address, :city, :state, :postal_code
    )
  end
end
