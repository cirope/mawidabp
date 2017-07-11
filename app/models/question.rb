class Question < ApplicationRecord
  include Auditable
  include Questions::Validations
  include Questions::Callbacks

  belongs_to :questionnaire, optional: true
  has_one :answer
  has_many :answer_options, dependent: :destroy

  def to_s
    question
  end
end
