class ProcessControl < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Comparable
  include ProcessControls::ControlObjectives
  include ProcessControls::DestroyValidation
  include ProcessControls::Obsolecence

  alias_attribute :label, :name

  # Named scopes
  scope :list, -> {
    order([
      "#{quoted_table_name}.#{qcn('best_practice_id')} ASC",
      "#{quoted_table_name}.#{qcn('order')} ASC"
    ])
  }
  scope :list_for_log, ->(id) { where(id: id)  }

  # Restricciones
  validates :name, :order, presence: true
  validates :name, length: { maximum: 255 }, allow_nil: true, allow_blank: true
  validates :order, numericality: { only_integer: true }
  validates_each :name do |record, attr, value|
    best_practice = record.best_practice

    is_duplicated = best_practice && best_practice.process_controls.any? do |pc|
      another_record = (!record.new_record? && pc.id != record.id) ||
        (record.new_record? && pc.object_id != record.object_id)

      pc.name? && record.name? && pc.name.downcase == record.name.downcase &&
        another_record && !record.marked_for_destruction?
    end

    record.errors.add attr, :taken if is_duplicated
  end
  validates_each :control_objectives do |record, attr, value|
    unless value.all? { |co| !co.marked_for_destruction? || co.can_be_destroyed? }
      record.errors.add attr, :locked
    end
  end

  # Relaciones
  belongs_to :best_practice

  def <=>(other)
    if other.kind_of?(ProcessControl)
      if self.best_practice_id == other.best_practice_id
        self.name <=> other.name
      else
        self.id <=> other.id
      end
    else
      -1
    end
  end

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label, :informal]
    }

    super(default_options.merge(options || {}))
  end

  def informal
    best_practice.try(:name)
  end
end
