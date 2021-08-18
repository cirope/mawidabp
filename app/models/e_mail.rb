class EMail < ApplicationRecord
  include Auditable
  include Emails::Fetch
  include Emails::Search
  include Emails::Scopes
  include Emails::Validations

  belongs_to :organization, optional: true
end
