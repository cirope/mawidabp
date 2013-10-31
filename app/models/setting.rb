class Setting < ActiveRecord::Base
  has_paper_trail

  attr_readonly :name

  default_scope { order('name ASC') }

  validates :name, :value, :organization_id, presence: true
  validates :name, :value, length: { maximum: 255 }
  validates :name, uniqueness:
    { case_sensitive: false, scope: :organization_id }

  validates :value, numericality:
    { only_integer: true, greater_than_or_equal_to: 0 }, if: :is_numericality?

  belongs_to :organization

  def to_s
    description
  end

  def is_numericality?
    DEFAULT_SETTINGS[name][:validates] == 'numericality' if DEFAULT_SETTINGS[name]
  end
end
