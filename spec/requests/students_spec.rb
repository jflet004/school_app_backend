# spec/requests/students_spec.rb
require "rails_helper"

RSpec.describe "Students API", type: :request do
  describe "GET /students" do
    it "returns a list of students with parent contacts" do
      create_list(:adult_student, 2)
      child = create(:child_student)
      create_list(:parent_contact, 2, student: child)

      get "/students"

      expect(response).to have_http_status(:ok)
      expect(json).to be_an(Array)
      expect(json.first).to include("id", "first_name", "student_type")
      # includes parent contacts
      expect(json.find { |s| s["id"] == child.id }["parent_contacts"].length).to eq(2)
    end
  end

  describe "POST /students" do
    let(:base_payload) do
      {
        first_name: "Maya",
        last_name: "Lopez",
        birthday: "2013-05-10",
        instrument_preference: "Violin",
        gender: "female",
        experience_years: "one_two",
        ethnicity: "hispanic_latino",
        email: "maya@example.com",
        phone_number: "555-123-4567",
        home_address: "123 Maple St",
        city: "Springfield",
        state: "MA",
        postal_code: "01103",
        household_size: "size_4",
        household_income: "between_50k_74_999",
        heard_about: "web"
      }
    end

    it "creates a child with nested parent contacts" do
      payload = {
        student: base_payload.merge(
          student_type: "child",
          current_school_name: "Springfield Middle",
          current_school_offers_arts: true,
          parent_contacts_attributes: [
            { parent_first_name: "Elena", parent_last_name: "Lopez", email: "elena@example.com" },
            { parent_first_name: "Carlos", parent_last_name: "Lopez", email: "carlos@example.com" }
          ]
        )
      }

      post "/students", params: payload

      expect(response).to have_http_status(:created)
      expect(json["id"]).to be_present
      expect(json["student_type"]).to eq("child")
      expect(json["parent_contacts"].size).to eq(2)
    end

    it "rejects a child when current_school_offers_arts is nil" do
      payload = {
        student: base_payload.merge(
          student_type: "child",
          current_school_name: "Springfield Middle"
          # missing current_school_offers_arts
        )
      }

      post "/students", params: payload

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"].join).to match(/Current school offers arts/i)
    end

    it "creates an adult" do
      payload = {
        student: base_payload.merge(
          student_type: "adult"
        )
      }

      post "/students", params: payload

      expect(response).to have_http_status(:created)
      expect(json["student_type"]).to eq("adult")
    end
  end

  describe "GET /students/:id" do
    it "shows a single student" do
      student = create(:adult_student)

      get "/students/#{student.id}"

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(student.id)
    end
  end

  describe "PATCH /students/:id" do
    it "updates attributes" do
      student = create(:adult_student, instrument_preference: "Piano")

      patch "/students/#{student.id}", params: { student: { instrument_preference: "Guitar" } }

      expect(response).to have_http_status(:ok)
      expect(json["instrument_preference"]).to eq("Guitar")
    end
  end

  describe "DELETE /students/:id" do
    it "deletes the student" do
      student = create(:adult_student)

      expect {
        delete "/students/#{student.id}"
      }.to change(Student, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
