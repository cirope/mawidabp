module Findings::Current
  extend ActiveSupport::Concern

  def current
    repeated? && repeated_in.present? ? repeated_leaf : self
  end
end
