module Polls::About
  extend ActiveSupport::Concern

  included do
    belongs_to :about, polymorphic: true, optional: true
  end
end
