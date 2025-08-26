class ImportBatch < ApplicationRecord
  has_one_attached :file

  has_many :import_facts, dependent: :delete_all

  enum status: { pending: 0, parsed: 1, imported: 2, failed: 3 }, _prefix: true
  validates :source, presence: true

  # Simple metadata helpers
  def filename
    file&.blob&.filename&.to_s
  end
end
