class Api::V1::PurchasesController < ApplicationController
    def create
        debugger
        # Validate required parameters
        unless params[:email].present? && params[:book_id].present?
            return render json: { 
            status: "error", 
            message: "Email and book_id are required" 
            }, status: :unprocessable_entity
        end

        user_email = params[:email]
        user_id = params[:user_id]        

        #Find a book
        begin
            @book = Book.find(params[:book_id])
        rescue ActiveRecord::RecordNotFound
           return render json: {
                status: {code: 404, message: 'Book not found'}
            }, status: :not_found
        end

        # Initialize payment
        paystack = PaystackService.new
        result = paystack.initialize_transaction(
            email: user_email,
            amount: @book.ebook_price,
            metadata: {
                book_id: @book.id,
                content_type: 'application/pdf'
            },
            callback_url: "#{ENV['FRONTEND_URL']}/payment/callback"
        )

        if result[:success]
            purchase = Purchase.create!(
                book: @book,
                amount: @book.ebook_price,
                content_type: 'ebook',
                purchase_status: 'pending',
                purchase_date: Time.now,
                transaction_reference: result[:data]["reference"]
                )
        render json: {
            status: true,
            message: "Authorization URL created",
            data: {
                authorization_url: result[:data]["authorization_url"],
                access_code: result[:data]["access_code"],
                reference: result[:data]["reference"]
            }
        }
    else 
        render json: {
            status: false,
            message: result[:error]
        }, status: :unprocessable_entity      
    end
end
