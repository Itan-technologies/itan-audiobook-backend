class Api::V1::Reader::FinishedBooksController < ApplicationController
  before_action :authenticate_reader!

  # GET /api/v1/reader/finished_books
  def index
    finished_reads = current_reader.reading_statuses
      .includes(book: { cover_image_attachment: :blob })
      .where(status: :finished)
      .order(updated_at: :desc)

    render json: {
      status: { code: 200 },
      data: finished_reads.map do |rs|
        {
          id: rs.id,
          book: {
            id: rs.book.id,
            title: rs.book.title,
            author: "#{rs.book.author.first_name} #{rs.book.author.last_name}",
            cover_image_url: (
              Rails.application.routes.url_helpers.url_for(rs.book.cover_image) if rs.book.cover_image.attached?
            )
          },
          last_read_at: rs.last_read_at,
          status: rs.status
        }
      end
    }
  end
end
