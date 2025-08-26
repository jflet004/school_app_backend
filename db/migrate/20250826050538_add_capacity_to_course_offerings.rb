class AddCapacityToCourseOfferings < ActiveRecord::Migration[7.1]
  def change
    add_column :course_offerings, :capacity, :integer
  end
end
