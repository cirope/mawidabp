class EMail < ActiveRecord::Base
  include Associations::DestroyPaperTrail
  include Auditable
  include Emails::Search
  include Emails::Scopes
  include Emails::Validations

  belongs_to :organization
end
