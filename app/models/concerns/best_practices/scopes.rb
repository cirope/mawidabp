module BestPractices::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order obsolete: :asc, name: :asc }
  end
end
