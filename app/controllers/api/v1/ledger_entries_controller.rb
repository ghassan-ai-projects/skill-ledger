module Api
  module V1
    class LedgerEntriesController < BaseController
      def index
        entries = LedgerEntry.includes(:from_account, :to_account)
        if params[:account_id].present?
          entries = entries.where(from_account_id: params[:account_id])
                            .or(LedgerEntry.where(to_account_id: params[:account_id]))
        end

        result = paginate(entries)
        paginated = result[:collection]
        meta = result[:meta]

        render json: {
          ledger_entries: paginated.as_json(
            include: {
              from_account: { only: %i[id name] },
              to_account: { only: %i[id name] }
            }
          ),
          meta: meta
        }
      end
    end
  end
end
