module Api
  module V1
    class LedgerEntriesController < ApplicationController
      def index
        entries = LedgerEntry.includes(:from_account, :to_account)
        if params[:account_id].present?
          entries = entries.where(from_account_id: params[:account_id])
                            .or(LedgerEntry.where(to_account_id: params[:account_id]))
        end
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
