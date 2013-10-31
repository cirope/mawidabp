class Setting < ActiveRecord::Base
  has_paper_trail

  attr_readonly :name

  default_scope { order('name ASC') }

  validates :name, :value, :organization_id, presence: true
  validates :name, :value, length: { maximum: 255 }
  validates :name, uniqueness: { case_sensitive: false, scope: :organization_id }

  belongs_to :organization

  def to_s
    description
  end
end
