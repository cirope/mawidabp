module Findings::Tasks
  extend ActiveSupport::Concern

  included do
    has_many :tasks, -> { order due_on: :asc }, dependent: :destroy

    accepts_nested_attributes_for :tasks, allow_destroy: true
  end
end
