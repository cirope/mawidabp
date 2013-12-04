class AnswerOption < ActiveRecord::Base
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Validaciones
  validates :option, presence: true
  validates_length_of :option, maximum: 255, allow_nil: true,
    allow_blank: true

  # Relaciones
  belongs_to :question
  has_one :answer_multi_choice
  has_many :answer_multi_choice
end
