class Task < ApplicationRecord
  include Auditable
  include Tasks::DueOnDates
  include Tasks::Expiration
  include Tasks::Status
  include Tasks::Validations

  belongs_to :finding, touch: true
  has_one :organization, through: :finding
  has_many :users, through: :finding

  def to_s
    description
  end

  def detailed_description
    [
      description,
      I18n.t("tasks.status.#{status}"),
      I18n.l(due_on, format: :minimal)
    ].join(' - ')
  end
end
