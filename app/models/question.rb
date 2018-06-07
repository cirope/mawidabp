class Question < ApplicationRecord
  include Auditable

  include Questions::Callbacks
  include Questions::Options
  include Questions::Scopes
  include Questions::Validations

  belongs_to :questionnaire, optional: true
  has_one :answer
  has_many :answer_options, dependent: :destroy

  def to_s
    question
  end
end
