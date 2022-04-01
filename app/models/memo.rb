class Memo < ApplicationRecord
  include Memos::CloseDate
  include Memos::FileModelMemos
  include Memos::PlanItem
  include Memos::RequiredByOptions
  include Memos::Scopes
  include Memos::Search
  include Memos::Validations

  belongs_to :period
  belongs_to :organization
end
