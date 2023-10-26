class Risk < ApplicationRecord
  include Risks::Relations
  include Risks::Scopes
  include Risks::Validation

  def to_s
    name
  end
end
