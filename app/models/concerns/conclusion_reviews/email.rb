module ConclusionReviews::Email
  extend ActiveSupport::Concern

  def send_by_email_to user, options = {}
    default_options = {
      organization_id: Organization.current_id,
      user_id:         PaperTrail.request.whodunnit
    }

    NotifierMailer.conclusion_review_notification(
      user, self, options.merge(default_options)
    ).deliver_later
  end
end
