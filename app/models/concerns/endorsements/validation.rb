module Endorsements::Validation
  extend ActiveSupport::Concern

  included do
    validates :reason, presence: true, unless: :new_record?
  end
end
