class PlanItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Atributos no persistentes
  attr_accessor :business_unit_data, :overloaded

  # Asociaciones que deben ser registradas cuando cambien
  @@associations_attributes_for_log = [:resource_ids]

   # Named scopes
  scope :list_unused, lambda { |period_id|
    {
      :include => [{:plan => :period}, :review],
      :conditions => [
        [
          "#{Plan.table_name}.period_id = :period_id",
          "#{Period.table_name}.organization_id = :organization_id",
          "#{Review.table_name}.plan_item_id IS NULL",
          "#{table_name}.business_unit_id IS NOT NULL",
        ].join(' AND '),
        {
          :period_id => period_id,
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => [
        "#{PlanItem.table_name}.order_number ASC",
        "#{PlanItem.table_name}.project ASC"
      ].join(', ')
    }
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  serialize :predecessors, Array
  
  # Restricciones
  validates :project, :order_number, :presence => true
  validates_length_of :project, :predecessors, :maximum => 255,
    :allow_nil => true, :allow_blank => true
  validates_numericality_of :order_number, :plan_id, :business_unit_id,
    :only_integer => true, :allow_nil => true
  validates :start, :timeliness => { :type => :date }
  validates :end, :timeliness => { :type => :date , :on_or_after => :start }
  validates_each :project do |record, attr, value|
    unless record.plan.try(:allow_duplication?)
      (record.plan.try(:plan_items) || []).each do |pi|
        another_record = (!record.new_record? && pi.id != record.id) ||
          (record.new_record? && pi.object_id != record.object_id)

        if another_record && pi.project == value && !pi.marked_for_destruction?
          record.errors.add attr, :taken
        end
      end
    end
  end
  validates_each :start, :end do |record, attr, value|
    parent = record.plan
    period = parent.try(:period)

    # VALIDACIÓN: Dentro del periodo
    if period && value && !value.between?(period.start, period.end)
      record.errors.add attr, :out_of_period
    end

    if parent && !parent.allow_overload?
      # VALIDACIÓN: Superposición de recursos
      resource_table = {}
      plan_items = parent.plan_items.reject { |pi| pi.marked_for_destruction? }

      plan_items.each do |plan_item|
        if record.order_number && plan_item.order_number < record.order_number
          plan_item.human_resource_utilizations.each do |resource_utilization|
            resource_id = resource_utilization.resource_id

            if resource_id && !resource_utilization.marked_for_destruction?
              resource_table[resource_id] ||= []
              resource_table[resource_id] << [plan_item.start, plan_item.end]
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
      unless record.predecessors.blank?
        predecessor_items = plan_items.select do |plan_item|
          record.predecessors.include?(plan_item.order_number)
        end

        if predecessor_items.any? { |pi| pi.end && value < pi.end }
          record.overloaded = true

          record.errors.add attr, :item_overload
        end
      end
    end
  end
  validates_each :predecessors do |record, attr, value|
    plan_items = record.plan ?
      record.plan.plan_items.reject { |pi| pi.marked_for_destruction? } : []
    order_numbers = plan_items.inject([]) do |orders, plan_item|
      orders << plan_item.order_number
    end

    unless value.all? { |predecessor| order_numbers.include?(predecessor) } &&
        value.all? { |predecessor| predecessor < record.order_number }
      record.errors.add attr, :invalid if value
    end
  end

  # Relaciones
  belongs_to :plan
  belongs_to :business_unit
  has_one :review
  has_many :resource_utilizations, :as => :resource_consumer,
    :dependent => :destroy

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

  def material_cost
    self.material_resource_utilizations.sum(&:cost)
  end

  def can_be_destroyed?
    if self.review
      self.errors.add_to_base I18n.t(:'plan.errors.plan_item_related')

      false
    else
      true
    end
  end

  def status_text(long = true)
    if self.try(:review).try(:has_final_review?)
      I18n.t("plan.item_status.concluded.#{long ? :long : :short}")
    elsif self.try(:review)
      if self.end >= Date.today
        I18n.t("plan.item_status.executing_in_time.#{long ? :long : :short}")
      else
        I18n.t("plan.item_status.executing_overtime.#{long ? :long : :short}")
      end
    elsif !self.try(:review) && self.try(:business_unit)
      if self.try(:start) && self.start < Date.today
        I18n.t("plan.item_status.delayed.#{long ? :long : :short}")
      end
    end
  end

  def status_color
    if self.try(:review).try(:has_final_review?)
      :green
    elsif self.try(:review)
      if self.end >= Date.today
        :gray
      else
        :yellow
      end
    elsif !self.try(:review) && self.try(:business_unit)
      if self.try(:start) && self.start < Date.today
        :red
      end
    end
  end

  def add_resource_data(pdf, show_description = true)
    pdf.move_pointer PDF_FONT_SIZE

    if show_description
      pdf.text "<b>(#{self.order_number})</b> #{self.project}" +
        (self.business_unit ? " (#{self.business_unit.name})" : ''),
        :font_size => PDF_FONT_SIZE
      pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)
    end

    pdf.add_destination "plan_cost_detail_#{self.id}", 'XYZ', 0, pdf.y

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