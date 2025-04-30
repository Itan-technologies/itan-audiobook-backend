class Api::V1::DirectUploadsController < ActiveStorage::DirectUploadsController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token

  def create
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: blob_args[:filename],
      byte_size: blob_args[:byte_size],
      checksum: blob_args[:checksum],
      content_type: blob_args[:content_type],
      metadata: blob_args[:metadata] || {}
    )

    render json: direct_upload_json(blob)
  rescue ActionController::ParameterMissing => e
    Rails.logger.error "Direct upload parameter error: #{e.message}"
    render json: { error: "Missing required parameter: #{e.param}" }, status: :bad_request
  rescue ActiveStorage::IntegrityError => e
    Rails.logger.error "Direct upload integrity error: #{e.message}"
    render json: { error: "File integrity error: #{e.message}" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "Direct upload error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: 'Upload preparation failed. Please try again.' }, status: :internal_server_error
  end

  private

  def blob_args
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, :metadata).to_h.symbolize_keys
  end

  def direct_upload_json(blob)
    blob.as_json(methods: :signed_id).merge(
      direct_upload: {
        url: blob.service_url_for_direct_upload,
        headers: blob.service_headers_for_direct_upload
      }
    )
  end
end
