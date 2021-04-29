class ActivityGroup < ApplicationRecord
  include Auditable
  include ActivityGroups::Validation
  include ActivityGroups::Scopes

  belongs_to :organization

  def to_s
    name
  end
end
