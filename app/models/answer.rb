class Answer < ActiveRecord::Base
  include PaperTrail::DependentDestroy

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Validaciones
  validates_length_of :comments, maximum: 255, allow_nil: true, allow_blank: true

  # Relaciones
  belongs_to :question
  belongs_to :poll
  belongs_to :answer_option

  class << self
    def new(attributes = nil, options = {})
      question = attributes.try :delete, :question

      return super if question.blank?

      raise 'Need a question associated with the answer' unless question

      klass = question.answer_multi_choice? ? AnswerMultiChoice : AnswerWritten

      klass.new attributes.merge(question_id: question.id), options
    end
  end
end
