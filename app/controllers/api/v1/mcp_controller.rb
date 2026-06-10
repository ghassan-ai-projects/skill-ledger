module Api
  module V1
    class McpController < BaseController
      def create
        payload = McpService.new(@current_account).handle(
          request_id: params[:id],
          method: params[:method],
          params: params[:params] || {}
        )

        render json: payload, status: :ok
      rescue McpService::Error => e
        render json: {
          jsonrpc: "2.0",
          id: params[:id],
          error: {
            code: e.code,
            message: e.message
          }
        }, status: :unprocessable_entity
      end
    end
  end
end
