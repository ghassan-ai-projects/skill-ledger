module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate!

      VALID_SORT_COLUMNS = %w[price name created_at].freeze
      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100

      private

      def authenticate!
        api_key = request.headers["X-API-Key"]
        @current_account = Account.find_by(api_key: api_key)
        return if @current_account

        render json: { error: "Invalid or missing API key", details: [] }, status: :unauthorized
      end

      def paginate(collection, default_per_page: DEFAULT_PER_PAGE)
        per_page = [ params[:per_page]&.to_i || default_per_page, MAX_PER_PAGE ].min
        per_page = 1 if per_page < 1
        page = [ params[:page]&.to_i || 1, 1 ].max

        total_count = collection.count
        total_pages = (total_count.to_f / per_page).ceil
        total_pages = 1 if total_pages < 1

        paginated = collection.offset((page - 1) * per_page).limit(per_page)

        {
          collection: paginated,
          meta: {
            current_page: page,
            total_pages: total_pages,
            total_count: total_count,
            per_page: per_page
          }
        }
      end

      def apply_sorting(collection, allowed_columns: VALID_SORT_COLUMNS, default_sort: "created_at", default_order: "desc")
        sort_column = params[:sort].presence || default_sort
        sort_order = params[:order].presence || default_order

        unless allowed_columns.include?(sort_column)
          render json: {
            error: "Invalid sort column '#{sort_column}'. Allowed: #{allowed_columns.join(', ')}",
            details: []
          }, status: :unprocessable_entity and return nil
        end

        unless %w[asc desc].include?(sort_order.downcase)
          sort_order = default_order
        end

        collection.order(Arel.sql("#{ActiveRecord::Base.connection.quote_column_name(sort_column)} #{sort_order}"))
      end
    end
  end
end
