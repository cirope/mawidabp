class Reviews::ActionsController < ApplicationController
  include PlanAndReviewApproval

  respond_to :html

  before_action :auth, :check_privileges, :set_title, :set_review
  before_action -> { check_plan_and_review_approval @review },
    only: [:edit, :update, :destroy]

  def update
    @review.approved? ? @review.draft! : @review.approved!

    redirect_to @review, notice: t("flash.reviews.actions.#{@review.status}")
  end

  private

    def set_review
      @review = Review.list.find params[:id]
    end
end
