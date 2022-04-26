module Memos::RequiredByOptions
  extend ActiveSupport::Concern

  included do
    REQUIRED_BY_OPTIONS = REQUIRED_BY_OPTIONS_MEMO
  end
end
