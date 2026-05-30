module Api
  module V1
    class LibraryController < BaseController
      # GET /api/v1/me/library
      def index
        render json: LibraryService.new(@current_account).call
      end
    end
  end
end
