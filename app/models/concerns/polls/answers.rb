module Polls::Answers
  extend ActiveSupport::Concern

  included do
    has_many :answers, -> {
      includes(:question).
        order("#{Question.quoted_table_name}.#{Question.qcn('sort_order')} ASC").
        references(:questions)
    }, dependent: :destroy

    accepts_nested_attributes_for :answers
  end
end
