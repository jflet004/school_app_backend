# spec/requests/parent_contacts_spec.rb
require "rails_helper"

RSpec.describe "ParentContacts API", type: :request do
  let!(:student) { create(:child_student) }

  describe "GET /students/:student_id/parent_contacts" do
    it "lists parent contacts for a student" do
      create_list(:parent_contact, 2, student: student)

      get "/students/#{student.id}/parent_contacts"

      expect(response).to have_http_status(:ok)
      expect(json.length).to eq(2)
      expect(json.first).to include("id", "parent_first_name")
    end
  end

  describe "POST /students/:student_id/parent_contacts" do
    it "creates a new parent contact" do
      params = {
        parent_contact: {
          parent_first_name: "Elena",
          parent_last_name: "Lopez",
          email: "elena@example.com"
        }
      }

      post "/students/#{student.id}/parent_contacts", params: params

      expect(response).to have_http_status(:created)
      expect(json["id"]).to be_present
      expect(json["parent_first_name"]).to eq("Elena")
    end
  end

  describe "PATCH /students/:student_id/parent_contacts/:id" do
    it "updates a parent contact" do
      contact = create(:parent_contact, student: student, phone_number: "111")

      patch "/students/#{student.id}/parent_contacts/#{contact.id}",
            params: { parent_contact: { phone_number: "222" } }

      expect(response).to have_http_status(:ok)
      expect(json["phone_number"]).to eq("222")
    end
  end

  describe "DELETE /students/:student_id/parent_contacts/:id" do
    it "deletes a parent contact" do
      contact = create(:parent_contact, student: student)

      expect {
        delete "/students/#{student.id}/parent_contacts/#{contact.id}"
      }.to change(ParentContact, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
