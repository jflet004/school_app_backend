class ImportBatchesController < ApplicationController
  before_action :set_import, only: [:show, :preview]

  # POST /import_batches
  # multipart/form-data with param :file
  def create
    file = params[:file]
    return render json: { error: "file is required" }, status: :bad_request unless file

    batch = ImportBatch.create!(source: "mms", status: :pending)
    batch.file.attach(file)
    render json: { id: batch.id, filename: batch.filename, status: batch.status }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # GET /import_batches/:id
  def show
    render json: {
      id: @batch.id,
      source: @batch.source,
      status: @batch.status,
      filename: @batch.filename,
      metadata: @batch.metadata
    }
  end

  # GET /import_batches/:id/preview
  def preview
    return render json: { error: "file missing" }, status: :unprocessable_content unless @batch.file.attached?

    columns = []
    rows = []

    @batch.file.blob.open do |tempfile|
      result = MMSImport::Parser.preview(tempfile.path, limit: (params[:limit] || 50).to_i)
      columns = result[:columns]
      rows    = result[:rows]
    end

    @batch.update!(status: :parsed)
    render json: { id: @batch.id, filename: @batch.filename, columns: columns, rows: rows }
  rescue => e
    @batch.update(status: :failed)
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_import
    @batch = ImportBatch.find(params[:id])
  end
end
