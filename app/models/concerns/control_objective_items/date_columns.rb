module ControlObjectiveItems::DateColumns
  extend ActiveSupport::Concern

  included do
    attribute :audit_date, :date
  end
end
