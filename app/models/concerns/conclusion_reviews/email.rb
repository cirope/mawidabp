module ConclusionReviews::Email
  extend ActiveSupport::Concern

  def send_by_email_to user, options = {}
    byebug if $rock
    default_options = {
      organization_id: Current.organization_id,
      user_id:         PaperTrail.request.whodunnit
    }
    byebug if $rock

    NotifierMailer.conclusion_review_notification(
      user, self, options.merge(default_options)
    ).deliver_later
  end
end
