class HelpContent < ActiveRecord::Base
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Restricciones
  validates :language, :presence => true
  validates :language, :length => {:maximum => 10}, :allow_nil => true,
    :allow_blank => true
  validates :language, :uniqueness => {:case_sensitive => false},
    :allow_blank => true, :allow_nil => true

  # Relaciones
  has_many :help_items, -> { order('order_number ASC') }, :dependent => :destroy

  accepts_nested_attributes_for :help_items, :allow_destroy => true
end
