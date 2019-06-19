class PermalinkModel < ApplicationRecord
  belongs_to :permalink
  belongs_to :model, polymorphic: true
end
