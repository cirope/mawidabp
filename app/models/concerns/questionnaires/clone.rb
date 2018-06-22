module Questionnaires::Clone
  extend ActiveSupport::Concern

  def clone_from(other)
    self.attributes = other.attributes.except(
      *%w[id lock_version created_at updated_at]
    )

    copy_questions_from other
  end

  private

    def copy_questions_from(other)
      other.questions.order(:sort_order).each do |q|
        questions.build(
          q.attributes.except(
            *%w[id questionnaire_id lock_version created_at updated_at]
          )
        )
      end
    end
end
