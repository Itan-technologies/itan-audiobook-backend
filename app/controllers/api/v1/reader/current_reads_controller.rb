class Api::V1::Reader::CurrentReadsController < ApplicationController
  before_action :authenticate_reader!

  # GET /api/v1/reader/current_reads
  def index
    current_reads = current_reader.reading_statuses
      .includes(book: { cover_image_attachment: :blob })
      .where(status: :in_progress)
      .order(updated_at: :desc)

    render json: {
      status: { code: 200 },
      data: current_reads.map do |rs|
        {
          id: rs.id,
          book: {
            id: rs.book.id,
            title: rs.book.title,
            author: "#{rs.book.author.first_name} #{rs.book.author.last_name}",
            cover_image_url: (
              Rails.application.routes.url_helpers.url_for(rs.book.cover_image) if rs.book.cover_image.attached?
            ),
            ebook_file_url: (
              Rails.application.routes.url_helpers.url_for(rs.book.ebook_file) if rs.book.ebook_file.attached?
            )
          },
          last_read_at: rs.last_read_at,
          status: rs.status
        }
      end
    }
  end

  # PATCH /api/v1/reader/current_reads/:book_id
  def update
    reading_status = current_reader.reading_statuses.find_or_initialize_by(book_id: params[:book_id])
    reading_status.status = params[:status] if params[:status].present?
    reading_status.last_read_at = Time.current

    if reading_status.save
      render json: { status: { code: 200, message: 'Reading status updated' }, data: reading_status }
    else
      render json: { status: { code: 422, message: reading_status.errors.full_messages } },
             status: :unprocessable_entity
    end
  end
end
