class Api::V1::Author::EarningsController < ApplicationController
  before_action :authenticate_author!

  # GET /api/v1/author/earnings/summary
  def summary
    render json: {
      earnings_summary: {
        total: current_author.total_earnings,
        pending_earnings: current_author.pending_earnings,
        approved_earnings: current_author.approved_earnings
      }
    }
  end

  # GET /api/v1/author/earnings/breakdowns
  def breakdowns
    render json: {
      monthly_breakdown: current_author.monthly_earnings,
      earnings_by_book: current_author.book_earnings
    }
  end

  # GET /api/v1/author/earnings/recent_sales
  def recent_sales
    sales = current_author.author_revenues
      .includes(purchase: :book)
      .order(created_at: :desc)
      .limit(10)

    render json: {
      recent_sales: sales.map do |sale|
        {
          id: sale.id,
          amount: sale.amount,
          book_title: sale.purchase&.book&.title || 'Unknown Book',
          content_type: sale.purchase&.content_type,
          purchase_date: sale.created_at,
          status: sale.status
        }
      end
    }
  end

  # GET /api/v1/author/earnings/approved_payments
  def approved_payments
    payments = current_author.author_revenues
      .where(status: 'approved')
      .order(paid_at: :desc)
      .limit(10)

    render json: {
      approved_payments: payments.map do |payment|
        {
          id: payment.id,
          amount: payment.amount,
          book_title: payment.purchase&.book&.title || 'Unknown Book',
          approval_date: payment.paid_at,
          payment_reference: payment.payment_reference&.last(8)
        }
      end
    }
  end

  def authenticate_author!
    return if current_author

    render json: { error: 'Unauthorized' }, status: :unauthorized
    nil
  end
end
