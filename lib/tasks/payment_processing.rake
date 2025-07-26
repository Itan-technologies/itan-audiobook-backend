# namespace :payments do
#     desc "Process monthly author payments"
#     task process_monthly: :environment do
#       # Only run on the 15th of each month
#       return unless Date.today.day == 15

#       Rails.logger.info "Starting monthly payment processing..."
#       min_payment_threshold = 10.0
#       processed_count = 0
#       skipped_count = 0

#       # Find all authors with pending payments above threshold
#       eligible_authors = Author.joins(:author_revenues)
#                               .where(author_revenues: { status: 'pending' })
#                               .group('authors.id')
#                               .having('SUM(author_revenues.amount) >= ?', min_payment_threshold)

#       Rails.logger.info "Found #{eligible_authors.count} eligible authors for payment"

#       # Generate a single batch ID for this monthly run
#       batch_id = "BATCH-#{Date.today.strftime('%Y%m')}-#{SecureRandom.hex(4)}"

#       # Process each eligible author
#       eligible_authors.each do |author|
#         begin
#           ActiveRecord::Base.transaction do
#             # Get pending revenues for this author
#             pending_revenues = AuthorRevenue.where(
#               author_id: author.id,
#               status: 'pending'
#             )

#             total_amount = pending_revenues.sum(:amount).to_f
#             sale_count = pending_revenues.count

#             payment_ref = "PAY-#{Date.today.strftime('%Y%m')}-#{SecureRandom.hex(3)}"

#             # Update all pending revenues to approved
#             pending_revenues.update_all(
#               status: 'approved',
#               paid_at: Time.current,
#               payment_batch_id: batch_id,
#               payment_reference: payment_ref,
#               notes: "Approved in monthly batch #{batch_id}"
#             )

#             # Send email notification
#             AuthorMailer.payment_processed(
#               author,
#               total_amount,
#               sale_count,
#               payment_ref
#             ).deliver_now # Use deliver_now in rake tasks

#             processed_count += 1
#             Rails.logger.info "Processed payment of $#{total_amount} for author #{author.id} (#{author.email})"
#           end
#         rescue => e
#           Rails.logger.error "Failed to process payment for author #{author.id}: #{e.message}"
#           skipped_count += 1
#         end
#       end

#       Rails.logger.info "Monthly payment processing completed: #{processed_count} processed, #{skipped_count} skipped"
#     end
# end
