module Findings::Code
  extend ActiveSupport::Concern

  def next_code(review = nil)
    raise 'Must be implemented in the subclasses'
  end
end
