module Api
  module V1
    class StatusController < ApplicationController
      skip_before_action :authenticate_user!, if: -> { defined?(authenticate_user!) }
      
      def index
        render json: {
          status: "API online",
          version: "1.0",
          endpoints: {
            authors: "/api/v1/authors",
            books: "/api/v1/books",
            readers: "/api/v1/readers"
          }
        }
      end
    end
  end
end