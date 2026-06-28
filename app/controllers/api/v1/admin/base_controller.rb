module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_admin!

        private

        def require_admin!
          render json: { error: "Admin access required", details: [] }, status: :forbidden unless @current_account&.admin?
        end
      end
    end
  end
end
