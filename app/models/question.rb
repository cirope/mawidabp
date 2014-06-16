class Question < ActiveRecord::Base

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  ANSWER_TYPES = {
    :written => 0,
    :multi_choice => 1
  }

  ANSWER_OPTIONS = [
    :strongly_agree,
    :agree,
    :neither_agree_nor_disagree,
    :disagree,
    :strongly_disagree
  ]

  ANSWER_OPTION_VALUES = {
    :strongly_agree => 100,
    :agree => 75,
    :neither_agree_nor_disagree => 50,
    :disagree => 25,
    :strongly_disagree => 0
  }

  before_create :set_default_answers
  before_validation :verify_multi_choice, on: :update
  before_destroy :can_be_destroyed?

  # Validaciones
  validates :sort_order, :question, :answer_type, :presence => true
  validates_numericality_of :sort_order, :only_integer => true, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :question, :scope => :questionnaire_id, :allow_nil => true, :allow_blank => true
  validates_length_of :question, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_inclusion_of :answer_type, :in => ANSWER_TYPES.values, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  has_many :answer_options, dependent: :destroy
  has_one :answer
  belongs_to :questionnaire

  ANSWER_TYPES.each do |answer_type, answer_value|
    define_method("answer_#{answer_type}?") { self.answer_type == answer_value }
  end

  private

    def set_default_answers
      assign_answer_options if answer_multi_choice?
    end

    def verify_multi_choice
      if answer_type_changed?
        if answer_multi_choice?
          assign_answer_options if answer_options.blank?
        else
          if answer.blank?
            answer_options.clear
          else
            errors.add :question, :answered
          end
        end
      end
    end

    def assign_answer_options
      Question::ANSWER_OPTIONS.each do |option|
        answer_options << AnswerOption.new(option: option)
      end
    end

    def can_be_destroyed?
      answer.blank?
    end
end
