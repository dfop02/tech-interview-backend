class ApplicationController < ActionController::API
  include ActionController::Cookies
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found(err)
    render json: { error: err.message }, status: :not_found
  end

  def bad_request(err)
    render json: { error: err.message }, status: :bad_request
  end
end
