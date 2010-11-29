class WorkflowItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
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
  validates_length_of :predecessors, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :task, :case_sensitive => false,
    :scope => :workflow_id
  validates_numericality_of :order_number, :workflow_id, :only_integer => true,
    :allow_nil => true
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
  has_many :resources, :through => :resource_utilizations, :uniq => true

  accepts_nested_attributes_for :resource_utilizations, :allow_destroy => true

  def <=>(other)
    self.order_number <=> other.order_number
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

  def cost
    self.resource_utilizations.to_a.sum(&:cost)
  end

  def human_cost
    self.human_resource_utilizations.sum(&:cost)
  end

  def human_unit_cost
    self.human_resource_utilizations.sum(&:units)
  end

  def material_cost
    self.material_resource_utilizations.sum(&:cost)
  end

  def check_if_is_frozen
    unless self.is_frozen? && self.changed?
      true
    else
      msg = I18n.t(:'workflow.readonly')
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
    pdf.move_pointer PDF_FONT_SIZE

    pdf.text "<b>#{self.order_number}</b>) #{self.task}",
      :font_size => PDF_FONT_SIZE

    pdf.add_destination "workflow_cost_detail_#{self.id}", 'XYZ', 0, pdf.y

    column_order = [['resource_id', 40], ['units', 20], ['cost_per_unit', 20],
      ['cost', 20]]
    columns = {}
    column_data = []
    currency_mask = "#{I18n.t(:'number.currency.format.unit')}%.2f"

    column_order.each do |col_name, col_width|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = ResourceUtilization.human_attribute_name col_name
        c.width = pdf.percent_width(col_width)
      end
    end

    self.resource_utilizations.each do |resource_utilization|
      column_data << {
        'resource_id' => resource_utilization.resource.resource_name.to_iso,
        'units' => resource_utilization.units,
        'cost_per_unit' => currency_mask % resource_utilization.cost_per_unit,
        'cost' => currency_mask % resource_utilization.cost
      }
    end

    column_data << {
      'resource_id' => '', 'units' => '', 'cost_per_unit' => '',
      'cost' => "<b>#{currency_mask % self.cost}</b>"
    }

    pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.map(&:first)
        table.split_rows = true
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_color = Color::RGB.from_percentage(95, 95, 95)
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end
  end
end