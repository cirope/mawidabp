class ProcessControl < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:control_objective_ids]

  # Named scopes
  scope :list, :order =>['best_practice_id ASC',
    "#{table_name}.order ASC"].join(', ')
  scope :list_for_period, lambda { |period_id|
    {
      :select => connection.distinct('process_controls.id, name', 'name'),
      :include => [:procedure_control_items => [:procedure_control]],
      :conditions => {
        :procedure_control_items =>
          {:procedure_controls => {:period_id => period_id}}
      },
      :order => "#{table_name}.order ASC"
    }
  }
  scope :list_for_log, lambda { |id|
    {
      :conditions => {:id => id}
    }
  }
  
  # Restricciones
  validates_presence_of :name, :order
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_numericality_of :order, :only_integer => true
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
    unless value.all? {|co| !co.marked_for_destruction? || co.can_be_destroyed?}
      record.errors.add attr, :locked
    end
  end
  
  # Relaciones
  belongs_to :best_practice
  has_many :procedure_control_items, :dependent => :destroy
  has_many :control_objectives, :dependent => :destroy, :order => '"order" ASC'

  accepts_nested_attributes_for :control_objectives, :allow_destroy => true

  def associations_attributes_for_log
    @@associations_attributes_for_log
  end

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

  def can_be_destroyed?
    unless self.control_objectives.all? { |co| co.can_be_destroyed? }
      errors = self.control_objectives.map do |co|
        co.errors.full_messages.join(APP_ENUM_SEPARATOR)
      end
      
      self.errors.add_to_base errors.reject { |e| e.blank? }.join(
        APP_ENUM_SEPARATOR)

      false
    else
      true
    end
  end
end