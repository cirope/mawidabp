class Achievement < ActiveRecord::Base
  include Auditable
  include Achievements::Validations

  belongs_to :benefit
  belongs_to :finding
end
