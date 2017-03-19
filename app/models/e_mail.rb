class EMail < ApplicationRecord
  include Auditable
  include Emails::Search
  include Emails::Scopes
  include Emails::Validations

  belongs_to :organization
end
