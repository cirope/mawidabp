module Questionnaires::Questions
  extend ActiveSupport::Concern

  included do
    has_many :questions, -> { order("#{Question.quoted_table_name}.#{Question.qcn('sort_order')} ASC") },
      dependent: :destroy

    accepts_nested_attributes_for :questions, allow_destroy: true
  end
end
