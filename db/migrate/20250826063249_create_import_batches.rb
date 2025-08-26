class CreateImportBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :import_batches do |t|
      t.string :source
      t.integer :status
      t.json :metadata

      t.timestamps
    end
  end
end
