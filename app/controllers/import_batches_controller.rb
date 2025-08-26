# app/controllers/import_batches_controller.rb
class ImportBatchesController < ApplicationController
  before_action :set_batch, only: [:show, :preview, :commit]

  def index
    limit = (params[:limit] || 100).to_i.clamp(1, 500)
    batches = ImportBatch.order(created_at: :desc).limit(limit)

    items = batches.map do |b|
      # fallback: if date_range missing, derive from facts for this batch
      dr = b.metadata&.dig("date_range")
      unless dr
        from = ImportFact.where(import_batch_id: b.id).minimum(:on_date)
        to   = ImportFact.where(import_batch_id: b.id).maximum(:on_date)
        dr = (from && to) ? { "from" => from, "to" => to } : nil
      end

      {
        id: b.id,
        filename: b.filename,
        status: b.status,
        created_at: b.created_at,
        mode: b.metadata&.dig("mode") || "facts",
        date_range: dr,
        summary: b.metadata&.dig("summary")
      }
    end

    render json: { items: items }
  end

  # POST /import_batches  (multipart form with :file)
  def create
    file = params[:file]
    return render(json: { error: "file is required" }, status: :bad_request) unless file

    batch = ImportBatch.create!(source: "mms", status: :pending)
    batch.file.attach(file)

    render json: { id: batch.id, filename: batch.filename, status: batch.status }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # GET /import_batches/:id
  def show
    return render json: { error: "batch not found" }, status: :not_found unless @batch
    render json: {
      id: @batch.id, source: @batch.source, status: @batch.status,
      filename: @batch.filename, metadata: @batch.metadata
    }
  end

  # GET /import_batches/:id/preview?limit=50|200|1000|all
  def preview
    return render json: { error: "batch not found" }, status: :not_found unless @batch
    return render json: { error: "file missing" }, status: :unprocessable_content unless @batch.file.attached?

    limit_param = params[:limit].to_s
    limit = case limit_param
            when "", nil then 200
            when "all"   then nil
            else limit_param.to_i
            end

    columns = []
    rows    = []

    @batch.file.blob.open do |tempfile|
      result  = ::MmsImport::Parser.preview(tempfile.path, limit: limit)
      columns = result[:columns]
      rows    = result[:rows]
    end

    @batch.update!(status: :parsed)
    render json: { id: @batch.id, filename: @batch.filename, columns: columns, rows: rows }
  rescue => e
    @batch.update(status: :failed) rescue nil
    render json: { error: e.message }, status: :unprocessable_content
  end

  # POST /import_batches/:id/commit
  def commit
    return render json: { error: "batch not found" }, status: :not_found unless @batch
    return render json: { error: "file missing" }, status: :unprocessable_content unless @batch.file.attached?

    mode = params[:mode].presence || "facts"
    result = @batch.file.blob.open { |t| ::MmsImport::CommitterFacts.commit(t.path, @batch.id) }

    summary = { facts: result.facts, skipped: result.skipped, errors: result.errors.size }
    @batch.update!(
      status: :imported,
      metadata: {
        mode: mode,
        filename: @batch.filename,
        date_range: { from: result.date_from, to: result.date_to },
        summary: summary,
        errors: result.errors
      }
    )

    render json: @batch.metadata, status: :ok
  rescue => e
    @batch.update(status: :failed) rescue nil
    render json: { error: e.message }, status: :unprocessable_content
  end

def destroy
  batch = ImportBatch.find_by(id: params[:id])
  return render json: { error: "batch not found" }, status: :not_found unless batch

  batch.destroy # thanks to dependent: :delete_all on import_facts
  head :no_content
end

  private
  def set_batch
    @batch = ImportBatch.find_by(id: params[:id])
  end
end
