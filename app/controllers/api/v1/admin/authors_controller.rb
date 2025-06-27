# app/controllers/api/v1/admin/authors_controller.rb
class Api::V1::Admin::AuthorsController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_author, only: [:show]
    
    # GET /api/v1/admin/authors
    def index
      @authors = Author.all.order(created_at: :desc)
      
      # Optional filtering capability
    #   @authors = case params[:status]
    #             when 'verified' then @authors.where(verified: true)
    #             when 'unverified' then @authors.where(verified: false)
    #             else @authors
    #             end
      
      render_authors_json(@authors)
    end
    
    # GET /api/v1/admin/authors/:id
    def show
      render_authors_json(@author)
    end
    
    private
    
    def set_author
      @author = Author.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: { code: 404, message: 'Author not found' }
      }, status: :not_found
    end
    
    def render_authors_json(authors, message = nil, status_code = 200)
      response = {
        status: { code: status_code }
      }
      
      response[:status][:message] = message if message
      
      if authors.is_a?(Author)
        response[:data] = AuthorSerializer.new(authors).serializable_hash[:data][:attributes]
      else
        response[:data] = AuthorSerializer.new(authors).serializable_hash[:data].map { |author| author[:attributes] }
      end
      
      render json: response
    end

    def authenticate_admin!
      unless current_admin
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end