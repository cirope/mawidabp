class WorkflowItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks para registrar los cambios en los modelos cuando son modificados o
  # creados
  before_destroy :can_be_destroyed?

  # Atributos serializabled
  serialize :predecessors, Array

  # Atributos no persistentes
  attr_accessor :overloaded

  # Restricciones
  validate :check_if_is_frozen
  validates :task, :order_number, :presence => true
  validates :task, :pdf_encoding => true
  validates :predecessors, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :order_number, :workflow_id, :numericality =>
    {:only_integer => true}, :allow_nil => true
  validates_date :start
  validates_date :end, :on_or_after => :start
  validates_each :start, :end do |record, attr, value|
    parent = record.workflow
    period = parent.period if parent

    # VALIDACIÓN: Dentro del periodo
    if period && value && !value.between?(period.start, period.end)
      record.errors.add attr, :out_of_period
    end

    if parent && !parent.allow_overload? && value
      # VALIDACIÓN: Superposición de recursos
      resource_table = {}
      workflow_items = parent.workflow_items.reject do |wi|
        wi.marked_for_destruction?
      end

      workflow_items.each do |wf_item|
        if record.order_number && wf_item.order_number < record.order_number
          wf_item.human_resource_utilizations.each do |resource_utilization|
            resource_id = resource_utilization.resource_id
            if resource_id && !resource_utilization.marked_for_destruction?
              resource_table[resource_id] ||= []
              resource_table[resource_id] << [wf_item.start, wf_item.end]
            end
          end
        end
      end

      record.human_resource_utilizations.each do |resource_utilization|
        resource_id = resource_utilization.resource_id

        if resource_id && !resource_utilization.marked_for_destruction?
          (resource_table[resource_id] || []).each do |start_date, end_date|
            if start_date && end_date && value.between?(start_date, end_date)
              record.overloaded = true

              record.errors.add attr, :resource_overload
            end
          end
        end
      end

      # VALIDACIÓN: Fecha incorrecta entre tareas relacionadas
      if record.predecessors && !record.predecessors.empty?
        predecessor_items = workflow_items.select do |wf_item|
          record.predecessors.include?(wf_item.order_number)
        end

        if predecessor_items.any? { |pi| pi.end && value < pi.end }
          record.overloaded = true

          record.errors.add attr, :item_overload
        end
      end
    end
  end
  validates_each :predecessors do |record, attr, value|
    workflow_items = record.workflow ?
      record.workflow.workflow_items.reject {|wi| wi.marked_for_destruction?} :
      []
    order_numbers = workflow_items.inject([]) do |orders, wf_item|
      orders << wf_item.order_number
    end

    unless value.all? { |predecessor| order_numbers.include?(predecessor) } &&
        value.all? { |predecessor| predecessor < record.order_number }
      record.errors.add attr, :invalid if value
    end
  end

  # Relaciones
  belongs_to :workflow
  has_many :resource_utilizations, :as => :resource_consumer,
    :dependent => :destroy

  accepts_nested_attributes_for :resource_utilizations, :allow_destroy => true

  def <=>(other)
    if other.kind_of?(WorkflowItem)
      self.order_number <=> other.order_number
    else
      -1
    end
  end

  def start
    super.try :to_date
  end

  def end
    super.try :to_date
  end

  def material_resource_utilizations
    self.resource_utilizations.select { |ru| ru.material? }
  end

  def human_resource_utilizations
    self.resource_utilizations.select { |ru| ru.human?}
  end

  def plain_predecessors
    self.predecessors.try(:to_sentence)
  end

  def plain_predecessors=(plain_predecessors)
    self.predecessors = (plain_predecessors || '').split(/\D+/).map do |p|
      p.to_i if p.respond_to?(:to_i)
    end.compact.sort
  end

  def human_units
    self.human_resource_utilizations.map(&:units).compact.sum
  end

  def material_units
    self.material_resource_utilizations.map(&:units).compact.sum
  end

  def units
    self.resource_utilizations.map(&:units).compact.sum
  end

  def check_if_is_frozen
    unless self.is_frozen? && self.changed?
      true
    else
      msg = I18n.t('workflow.readonly')
      self.errors.add :base, msg unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def can_be_destroyed?
    !self.is_frozen?
  end

  def is_frozen?
    self.workflow.try(:is_frozen?)
  end

  def add_resource_data(pdf)
    pdf.move_down PDF_FONT_SIZE

    pdf.text "<b>#{self.order_number}</b>) #{self.task}",
      :font_size => PDF_FONT_SIZE, :inline_format => true

    column_order = [['resource_id', 80], ['units', 20]]
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_name, col_width|
      column_headers << ResourceUtilization.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_width)
    end

    self.resource_utilizations.each do |resource_utilization|
      column_data << [
        resource_utilization.resource.resource_name,
        resource_utilization.units
      ]
    end

    column_data << [
      '', "<b>#{'%.2f' % units}</b>"
    ]

    pdf.move_down((PDF_FONT_SIZE * 0.5).round)

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end
  end
end
