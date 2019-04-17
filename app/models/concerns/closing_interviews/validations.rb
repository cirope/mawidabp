module ClosingInterviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :interview_date, presence: true, timeliness: { type: :date }
    validates :review_id, presence: true
    validates :findings_summary, :recommendations_summary, :suggestions,
      :comments, :audit_comments, :responsible_comments, pdf_encoding: true
  end
end
