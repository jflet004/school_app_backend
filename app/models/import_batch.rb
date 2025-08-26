class ImportBatch < ApplicationRecord
  has_one_attached :file

  enum status: { pending: 0, parsed: 1, committed: 2, failed: 3 }
  validates :source, presence: true

  # Simple metadata helpers
  def filename
    file&.blob&.filename&.to_s
  end
end
