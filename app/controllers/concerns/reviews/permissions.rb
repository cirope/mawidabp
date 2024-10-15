module Reviews::Permissions
  extend ActiveSupport::Concern

  def check_review_permissions object
    if object
      review = object.kind_of?(Review) ? object : object.send(:review)

      unless review&.can_be_modified_by? @auth_user
        redirect_to object.class, alert: t('messages.not_allowed')
      end
    end
  end
end
