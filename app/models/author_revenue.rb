class AuthorRevenue < ApplicationRecord
    belongs_to :author
    belongs_to :purchase
    
    validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :status, presence: true, inclusion: { in: %w[pending processing approved] }
    
    scope :pending, -> { where(status: 'pending') }
    scope :processing, -> { where(status: 'processing') }
    scope :approved, -> { where(status: 'approved') }
    
    # Find revenues eligible for payout (pending, above minimum threshold)
    scope :payable, -> { pending.where('amount >= ?', 5.0) }
    
    # Group pending revenues by author for batch processing
    scope :by_author, -> { group(:author_id).sum(:amount) }
    
    # Analytics - group by month
    scope :monthly_totals, -> { 
      group("DATE_TRUNC('month', created_at)").sum(:amount) 
    }
    
    def mark_as_approved!(payment_ref = nil, batch_id = nil)
      update!(
        status: 'approved',
        paid_at: Time.current,
        payment_reference: payment_ref,
        payment_batch_id: batch_id
      )
    end
end