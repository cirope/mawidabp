module TimeConsumptions::Scopes
  extend ActiveSupport::Concern

  def review?
    resource_type == 'Review'
  end

  module ClassMethods
    def between start_date, end_date
      where date: start_date..end_date
    end
  end
end
