class Issue < ApplicationRecord
  include Auditable
  include Issues::Validation

  belongs_to :finding, touch: true, inverse_of: :issues

  def to_s
    [customer, operation].reject(&:blank).join ' - '
  end
end
