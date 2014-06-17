module Questionnaires::Questions
  extend ActiveSupport::Concern

  included do
    has_many :questions, -> { order("#{Question.table_name}.sort_order ASC") },
      dependent: :destroy

    accepts_nested_attributes_for :questions, allow_destroy: true
  end
end
