class Cost < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  scope :audit, :conditions => {:cost_type => 'audit'}
  scope :audited, :conditions => {:cost_type => 'audited'}
  
  # Restricciones
  validates_presence_of :cost, :cost_type, :user_id, :item_id, :item_type
  validates_numericality_of :user_id, :item_id, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validates_numericality_of :cost, :allow_nil => true, :allow_blank => true,
    :greater_than_or_equal_to => 0

  # Relaciones
  belongs_to :user
  belongs_to :item, :polymorphic => true, :readonly => true

  def raw_cost=(raw_cost)
    self.cost = raw_cost.fetch_time / 3600.0 unless raw_cost.blank?
  end

  def raw_cost
    self.cost.try(:to_s)
  end
end