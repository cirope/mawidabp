class ActivityGroup < ApplicationRecord
  include Auditable
  include ActivityGroups::Activities
  include ActivityGroups::DestroyValidation
  include ActivityGroups::Scopes
  include ActivityGroups::Validation

  belongs_to :organization

  def to_s
    name
  end
end
