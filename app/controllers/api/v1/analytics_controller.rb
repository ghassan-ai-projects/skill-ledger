module Api
  module V1
    class AnalyticsController < BaseController
      # GET /api/v1/authors/:id/analytics?period=all
      def show
        result = AnalyticsService.new(@current_account).show(
          author_id: params[:id],
          period: params[:period]
        )
        render json: result
      rescue AnalyticsService::Forbidden => e
        render json: { error: e.message, details: [] }, status: :forbidden
      end

      # GET /api/v1/authors/:id/earnings?period=all
      def earnings
        result = AnalyticsService.new(@current_account).earnings(
          author_id: params[:id],
          period: params[:period]
        )
        render json: result
      rescue AnalyticsService::Forbidden => e
        render json: { error: e.message, details: [] }, status: :forbidden
      end
    end
  end
end
