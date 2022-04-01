module Memos::RequiredByOptions
  extend ActiveSupport::Concern

  included do
    REQUIRED_BY_OPTIONS = %w[AP AF AC AS]
  end
end
