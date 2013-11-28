class ControlObjective < ActiveRecord::Base
  include Parameters::Relevance
  include Parameters::Risk

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Named scopes
  scope :list, -> {
    order(['process_control_id ASC', "#{table_name}.order ASC"])
  }
  scope :list_for_process_control, ->(process_control) {
    where(:process_control_id => process_control.id).order(
      ['process_control_id ASC', "#{table_name}.order ASC"]
    )
  }

  # Restricciones
  validates :name, :presence => true
  validates :relevance, :risk, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :process_control_id}
  validates_each :control do |record, attr, value|
    has_active_control = value && !value.marked_for_destruction?

    record.errors.add attr, :blank unless has_active_control
  end

  # Relaciones
  belongs_to :process_control
  has_many :control_objective_items, :inverse_of => :control_objective,
    :dependent => :nullify
  has_many :procedure_control_subitems, :inverse_of => :control_objective,
    :dependent => :nullify
  has_one :control, -> { order("#{Control.table_name}.order ASC") },
    :as => :controllable, :dependent => :destroy

  accepts_nested_attributes_for :control, :allow_destroy => true

  def initialize(attributes = nil, options = {})
    super(attributes, options)

    self.build_control unless self.control
  end

  def can_be_destroyed?
    unless self.control_objective_items.blank? &&
        self.procedure_control_subitems.blank?
      self.errors.add :base, I18n.t('control_objective.errors.related')

      false
    else
      true
    end
  end

  def risk_text
    risk = self.class.risks.detect { |r| r.last == self.risk }

    risk ? I18n.t("risk_types.#{risk.first}") : ''
  end
end
