module Polls::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :build_questions
    before_validation :set_answered, on: :update
  end

  private

    def build_questions
      if questionnaire && answers.empty?
        questionnaire.questions.each do |question|
          answers.build(question: question, type: question.answer_type_name)
        end
      end
    end

    def set_answered
      self.answered = temporary_polls_setting.value == '1' ? answers.all?(&:completed?) : true
    end

    def temporary_polls_setting
      Current.organization.settings.find_by(name: 'temporary_polls') ||
        OpenStruct.new(DEFAULT_SETTINGS[:temporary_polls])
    end
end
