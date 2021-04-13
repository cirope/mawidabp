module Oportunities::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
    after_commit :send_mail_to_supervisor, on: :create
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end

    def send_mail_to_supervisor
      supervisors = self.finding_user_assignments.map(&:user).select {|u| u.manager? || u.supervisor?}

      if supervisors.any?
        NotifierMailer.notify_new_oportunity(supervisors, self).deliver_now
      end
    end
end
