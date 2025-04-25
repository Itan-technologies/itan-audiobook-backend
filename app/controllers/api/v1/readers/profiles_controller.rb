class Api::V1::Readers::ProfilesController < ApplicationController
    before_action :authenticate_reader!
    respond_to :json

    def create
        @reader = current_reader.update(readers_params)
        if @reader.persisted?
            render json : {
                status: {},
                data: {}
            }
        else
            render json: {
                status: {code: 401, message: 'Unable to create profile'}                
            }, :unauthorized
    end

    def show 

    end

    def readers_params

    end
end