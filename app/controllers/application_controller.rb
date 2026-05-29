class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from LedgerTransactionService::InsufficientBalanceError, with: :insufficient_balance
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def not_found(exception)
    render json: { error: exception.message, details: [] }, status: :not_found
  end

  def record_invalid(exception)
    render json: {
      error: "Validation failed",
      details: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def insufficient_balance(exception)
    render json: { error: exception.message, details: [] }, status: :unprocessable_entity
  end

  def parameter_missing(exception)
    render json: {
      error: "Missing required parameter",
      details: [exception.message]
    }, status: :bad_request
  end
end
