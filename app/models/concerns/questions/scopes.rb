module Questions::Scopes
  extend ActiveSupport::Concern

  included do
    ::Question::ANSWER_TYPES.each do |name, value|
      scope name, -> { where answer_type: value }
    end
  end
end
