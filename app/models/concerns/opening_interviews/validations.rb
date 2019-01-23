module OpeningInterviews::Validations
  extend ActiveSupport::Concern

  included do
    validates :interview_date, :start_date, :end_date, presence: true,
      timeliness: { type: :date }
    validates :objective, :review_id, presence: true
    validates :objective, :program, :scope, :suggestions, :comments,
      pdf_encoding: true
  end
end
