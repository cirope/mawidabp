module Reviews::CurrentUserScoped
  extend ActiveSupport::Concern

  def scoped_reviews_for model
    collection = model.list
    collection = collection.merge Review.scoped_by(model, @auth_user) if review_filtered_by_user_assignments?

    collection
  end

  def review_filtered_by_user_assignments?
    setting         = current_organization.settings.find_by name: 'review_filtered_by_user_assignments'
    review_filtered = setting ? setting.value : DEFAULT_SETTINGS[:review_filtered_by_user_assignments][:value]

    review_filtered.to_i != 0
  end
end
