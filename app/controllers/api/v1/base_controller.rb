module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate!

      private

      def authenticate!
        api_key = request.headers["X-API-Key"]
        @current_account = Account.find_by(api_key: api_key)
        return if @current_account

        render json: { error: "Invalid or missing API key", details: [] }, status: :unauthorized
      end
    end
  end
end
