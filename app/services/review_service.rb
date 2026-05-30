class ReviewService
  class Error < StandardError; end

  def initialize(current_account)
    @current_account = current_account
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create(execution_id:, rating:, review_text: nil)
    execution = Execution.find(execution_id)

    unless execution.buyer_id == @current_account.id
      raise Error, "Only the buyer can review this execution"
    end

    unless execution.status == "completed"
      raise Error, "Can only review completed executions"
    end

    if execution.skill.author_id == @current_account.id
      raise Error, "Cannot review your own skill"
    end

    if execution.review.present?
      raise Error, "Execution already has a review"
    end

    review = execution.build_review(
      rating: rating,
      review_text: review_text
    )

    unless review.save
      raise Error, review.errors.full_messages.to_sentence
    end

    review
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
