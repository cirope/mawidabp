module Reviews::CurrentUserScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_reviews
  end

  private

    def set_reviews
      @reviews = Review.list
      @reviews = @reviews.scoped_by current_user if review_filtered_by_user_assignments?
    end

    def review_filtered_by_user_assignments?
      setting         = current_organization.settings.find_by name: 'review_filtered_by_user_assignments'
      review_filtered = setting ? setting.value : DEFAULT_SETTINGS[:review_filtered_by_user_assignments][:value]

      review_filtered.to_i != 0
    end
end
