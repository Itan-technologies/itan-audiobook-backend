class Api::V1::Authors::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    # If accessed directly from email, redirect to frontend
    if request.format.html?
      if resource.errors.empty?
        redirect_to "https://publish.itan.app/author/confirmation-success",
        allow_other_host: true
      else
        redirect_to "https://publish.itan.app/author/confirmation-error",
        allow_other_host: true
      end
    else
      render json: {
        status: { code: 422, message: resource.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
      
    end
  end  
  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)

    if successfully_sent?(resource)
      render json: {
        status: { code: 200, message: 'Confirmation instructions sent successfully.' }
      }
    else
      render json: {
        status: { code: 422, message: resource.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(_resource_name)
    nil
  end

  # The path used after confirmation.
  def after_confirmation_path_for(_resource_name, _resource)
    nil
  end
end
