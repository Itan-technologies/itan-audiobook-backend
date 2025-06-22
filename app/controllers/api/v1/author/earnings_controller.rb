class Api::V1::Author::EarningsController <  ApplicationController
  before_action :authenticate_author!

    # GET /api/v1/author/earnings
    # Returns earnings summary for the current author
    # Includes total earnings, pending earnings, paid earnings,
    # monthly earnings, book earnings, recent sales, and recent payments
    def index
      @total_earnings = current_author.total_earnings
      @pending_earnings = current_author.pending_earnings
      @paid_earnings = current_author.paid_earnings
      
      @monthly_earnings = current_author.monthly_earnings
      @book_earnings = current_author.book_earnings
      
      sales = current_author.author_revenues
                          .includes(purchase: :book)
                          .order(created_at: :desc)
                          .limit(10)
                          
      payments = current_author.author_revenues
                            .where(status: 'approved')
                            .order(paid_at: :desc)
                            .limit(10)
      
      # Return only necessary information
      render json: {
        earnings_summary: {
          total: @total_earnings,
          pending: @pending_earnings,
          paid: @paid_earnings
        },
        monthly_breakdown: @monthly_earnings,
        earnings_by_book: @book_earnings,
        recent_sales: sales.map { |sale| {
          id: sale.id,
          amount: sale.amount,
          book_title: sale.purchase&.book&.title || 'Unknown Book',
          content_type: sale.purchase&.content_type,
          purchase_date: sale.created_at,
          status: sale.status
        }},
        recent_payments: payments.map { |payment| {
          id: payment.id,
          amount: payment.amount,
          book_title: payment.purchase&.book&.title || 'Unknown Book',
          payment_date: payment.paid_at,
          payment_reference: payment.payment_reference&.last(8)
        }}
      }
    end

    # def by_book
    #   book_earnings = current_author.author_revenues
    #                                .joins(purchase: :book)
    #                                .group('books.id, books.title')
    #                                .sum(:amount)
                                   
    #   render json: { book_earnings: book_earnings }
    # end
end
