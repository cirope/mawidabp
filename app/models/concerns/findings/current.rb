module Findings::Current
  extend ActiveSupport::Concern

  def current
    latest || self
  end
end
