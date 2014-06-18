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
          answers.build(question: question)
        end
      end
    end

    def set_answered
      self.answered = true
    end
end
