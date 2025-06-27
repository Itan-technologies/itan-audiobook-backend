class Api::V1::Admin::AnalyticsController < ApplicationController
  before_action :authenticate_admin!  
  
  def financial_summary
      # Date range filtering
      start_date = params[:start_date]&.to_date || 30.days.ago.to_date
      end_date = params[:end_date]&.to_date || Date.today
      
      # Get purchases in date range
      purchases = Purchase.where(purchase_status: 'completed')
                         .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      
      # Calculate totals
      render json: {
        period: {start_date: start_date, end_date: end_date},
        total_revenue: purchases.sum(:amount) / 100.0,
        paystack_fees: purchases.sum(:paystack_fee),
        delivery_fees: purchases.sum(:delivery_fee),
        author_royalties: purchases.sum(:author_revenue_amount),
        platform_profit: purchases.sum(:admin_revenue),
        completed_purchases_count: purchases.count,
        breakdown_by_day: purchases.group_by_day(:created_at).sum(:amount)
                              .transform_values { |amount| amount / 100.0 }
      }
  end

  private
  
  def authenticate_admin!
    unless current_admin
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end