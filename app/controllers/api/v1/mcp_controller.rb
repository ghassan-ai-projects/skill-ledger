module Api
  module V1
    class McpController < BaseController
      def create
        payload = McpService.new(@current_account).handle(
          request_id: params[:id],
          method: params[:method],
          params: normalize_params(params[:params])
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

      private

      def normalize_params(value)
        return {} if value.nil?
        return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)

        value
      end
    end
  end
end
