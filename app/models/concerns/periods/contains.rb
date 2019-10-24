module Periods::Contains
  extend ActiveSupport::Concern

  def contains? date
    date.between? self.start, self.end
  end
end
