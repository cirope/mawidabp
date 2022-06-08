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

  after_find do |memo|
    if Memo::REQUIRED_BY_OPTIONS.exclude?(required_by)
      memo.manual_required_by = true
      memo.required_by_text   = required_by
      memo.required_by        = nil
    else
      memo.manual_required_by = false
    end
  end
end
