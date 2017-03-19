class Question < ApplicationRecord
  include Auditable
  include Questions::Validations
  include Questions::Callbacks

  has_one :answer
  belongs_to :questionnaire
  has_many :answer_options, dependent: :destroy

  def to_s
    question
  end
end
