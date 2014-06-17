module Questions::Callbacks
  extend ActiveSupport::Concern
  include Questions::Constants

  included do
    before_create :set_default_answers
    before_validation :verify_multi_choice, on: :update
    before_destroy :can_be_destroyed?
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
      ANSWER_OPTIONS.each do |option|
        answer_options << AnswerOption.new(option: option)
      end
    end

    def can_be_destroyed?
      answer.blank?
    end
end
