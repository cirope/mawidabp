class ControlObjective < ApplicationRecord
  include Auditable
  include Parameters::Relevance
  include Parameters::Risk
  include Taggable

  mount_uploader :support, FileUploader

  delegate :organization_id, to: :best_practice, allow_nil: true

  # Callbacks
  before_destroy :check_if_can_be_destroyed

  # Named scopes
  scope :list, -> {
    order([
      "#{quoted_table_name}.#{qcn('process_control_id')} ASC",
      "#{quoted_table_name}.#{qcn('order')} ASC"
    ])
  }
  scope :list_for_process_control, ->(process_control) {
    where(process_control_id: process_control.id).order([
      "#{quoted_table_name}.#{qcn('process_control_id')} ASC",
      "#{quoted_table_name}.#{qcn('order')} ASC"
    ])
  }

  # Restricciones
  validates :name, pdf_encoding: true, presence: true
  validates :relevance, :risk, numericality: { only_integer: true },
    allow_nil: true, allow_blank: true
  validates_each :control do |record, attr, value|
    has_active_control = value && !value.marked_for_destruction?

    record.errors.add attr, :blank unless has_active_control
  end

  # Relaciones
  belongs_to :process_control, optional: true
  has_one :best_practice, through: :process_control
  has_many :control_objective_items, inverse_of: :control_objective,
    dependent: :nullify
  has_one :control, -> { order("#{Control.quoted_table_name}.#{Control.qcn('order')} ASC") },
    as: :controllable, dependent: :destroy

  accepts_nested_attributes_for :control, allow_destroy: true

  def initialize(attributes = nil)
    super(attributes)

    self.build_control unless self.control
  end

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def label
    name
  end

  def informal
    process_control.try(:name)
  end

  def can_be_destroyed?
    if self.control_objective_items.any?
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

  def identifier
    support.identifier || support_identifier
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
