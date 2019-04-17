module Questions::Callbacks
  extend ActiveSupport::Concern
  include Questions::Constants

  included do
    before_create :set_default_answers
    before_validation :verify_multi_choice, on: :update
  end

  private

    def set_default_answers
      assign_answer_options if options.any?
    end

    def verify_multi_choice
      if answer_type_changed? && questionnaire.polls.empty?
        if options.any?
          answer_options.clear
          assign_answer_options
        else
          if answer.blank?
            answer_options.clear
          else
            errors.add :question, :answered
          end
        end
      elsif answer_type_changed? && questionnaire.polls.any?
        errors.add :answer_type, :used
      end
    end

    def assign_answer_options
      options.each do |option|
        answer_options << AnswerOption.new(option: option)
      end
    end
end
