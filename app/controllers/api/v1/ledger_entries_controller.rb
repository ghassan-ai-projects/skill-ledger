module Api
  module V1
    class LedgerEntriesController < ApplicationController
      def index
        entries = LedgerEntry.includes(:from_account, :to_account).all
        render json: entries.as_json(
          include: {
            from_account: { only: %i[id name] },
            to_account: { only: %i[id name] }
          }
        )
      end
    end
  end
end
