# Rails.application.config.after_initialize do
#   require 'active_storage/service/s3_service'
  
#   # Update the AWS SDK configuration to disable checksum validation
#   Aws.config.update({
#     retry_limit: 3,
#     http_wire_trace: false,
#     compute_checksums: false  # Disable CRC32 calculation
#   })
  
#   ActiveStorage::Service::S3Service.class_eval do
#     # Add a method to override upload options
#     private def upload_options
#       options = super rescue {}
#       options.merge(checksum_algorithm: nil) # Disable checksum algorithm
#     end
    
#     # Override the upload_with_single_part method to remove checksum verification
#     private def upload_with_single_part(key, io, checksum: nil, content_type: nil, content_disposition: nil, custom_metadata: {})
#       # Remove content_md5 from the parameters to skip MD5 checksum verification
#       begin
#         options = upload_options
#         object_for(key).put(
#           body: io, 
#           content_type: content_type, 
#           content_disposition: content_disposition, 
#           metadata: custom_metadata, 
#           **options
#         )
#       rescue Aws::S3::Errors::BadDigest, StandardError => e
#         Rails.logger.warn "S3 error for key #{key} - #{e.class}: #{e.message}"
#         # Retry without any checksums
#         object_for(key).put(
#           body: io, 
#           content_type: content_type, 
#           content_disposition: content_disposition, 
#           metadata: custom_metadata
#         )
#       end
#     end
#   end
  
#   # Confirm the patch was applied
#   Rails.logger.info "✅ ActiveStorage S3Service patched to disable all checksum verification"
# end
