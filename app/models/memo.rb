class Memo < ApplicationRecord
  include Memos::BicPdf
  include Memos::CloseDate
  include Memos::DefaultPdf
  include Memos::FileModelMemos
  include Memos::Pdf
  include Memos::PlanItem
  include Memos::RequiredByOptions
  include Memos::Scopes
  include Memos::Search
  include Memos::Validations

  belongs_to :period
  belongs_to :organization

  attr_accessor :manual_required_by, :required_by_text
end
