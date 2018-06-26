module Questionnaires::Questions
  extend ActiveSupport::Concern

  included do
    has_many :questions, -> {
      order Arel.sql("#{Question.quoted_table_name}.#{Question.qcn('sort_order')} ASC")
    }, dependent: :destroy
    has_many :answer_options, through: :questions

    accepts_nested_attributes_for :questions, allow_destroy: true
  end
end
