class PlanItem < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Atributos no persistentes
  attr_accessor :business_unit_data, :overloaded

  # Named scopes
  scope :list_unused, ->(period_id) {
    includes(:review, :plan).where(
      [
        "#{Plan.table_name}.period_id = :period_id",
        "#{Review.table_name}.plan_item_id IS NULL",
        "#{table_name}.business_unit_id IS NOT NULL",
      ].join(' AND '),
      { :period_id => period_id }
    ).references(:plans, :reviews).order(
      [
        "#{PlanItem.table_name}.order_number ASC",
        "#{PlanItem.table_name}.project ASC"
      ]
    )
  }
  scope :for_business_unit_type, ->(business_unit_type) {
    if business_unit_type.to_i > 0
      condition = "#{BusinessUnit.table_name}.business_unit_type_id = :but_id"
    elsif !business_unit_type.blank?
      condition = "#{BusinessUnit.table_name}.business_unit_type_id IS NULL"
    end

    includes(:business_unit).where(
      condition, :but_id => business_unit_type.to_i
    ).order('order_number ASC').references(:business_units)
  }
  scope :with_business_unit, -> { where("#{table_name}.business_unit_id IS NOT NULL") }

  # Callbacks
  #before_destroy :can_be_destroyed?

  serialize :predecessors, Array

  # Restricciones
  validates :project, :order_number, :presence => true
  validates :project, :predecessors, :length => {:maximum => 255},
    :allow_nil => true, :allow_blank => true
  validates :order_number, :plan_id, :business_unit_id,
    :numericality => {:only_integer => true}, :allow_nil => true
  validates_date :start
  validates_date :end, :on_or_after => :start
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
  has_one :review, dependent: :destroy
  has_one :business_unit_type, :through => :business_unit
  has_many :resource_utilizations, :as => :resource_consumer,
    :dependent => :destroy

  accepts_nested_attributes_for :resource_utilizations, :allow_destroy => true

  def <=>(other)
    self.order_number <=> other.order_number
  end

  def ==(other)
    if other.kind_of?(PlanItem)
      if self.new_record? && other.new_record?
        self.object_id == other.object_id
      else
        self.id == other.id
      end
    else
      -1
    end
  end

  def material_resource_utilizations
    self.resource_utilizations.select(&:material?)
  end

  def human_resource_utilizations
    self.resource_utilizations.select(&:human?)
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
      self.errors.add :base, I18n.t('plan.errors.plan_item_related')

      false
    else
      true
    end
  end

  def status_text(long = true)
    if self.try(:review).try(:has_final_review?)
      I18n.t(:"plan.item_status.concluded.#{long ? :long : :short}")
    elsif self.try(:review)
      if self.end >= Date.today
        I18n.t(:"plan.item_status.executing_in_time.#{long ? :long : :short}")
      else
        I18n.t(:"plan.item_status.executing_overtime.#{long ? :long : :short}")
      end
    elsif !self.try(:review) && self.try(:business_unit)
      if self.try(:start) && self.start < Date.today
        I18n.t(:"plan.item_status.delayed.#{long ? :long : :short}")
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

  def self.between(_start, _end)
    where(
      "#{table_name}.start >= :start AND #{table_name}.end <= :end",
      :start => _start, :end => _end
    )
  end

  def add_resource_data(pdf, show_description = true)
    pdf.move_down PDF_FONT_SIZE

    if show_description
      pdf.text "<b>(#{self.order_number})</b> #{self.project}" +
        (self.business_unit ? " (#{self.business_unit.name})" : ''),
        :font_size => PDF_FONT_SIZE, :inline_format => true
      pdf.move_down((PDF_FONT_SIZE * 0.5).round)
    end

    column_order = [['resource_id', 40], ['units', 20], ['cost_per_unit', 20],
      ['cost', 20]]
    column_data, column_headers, column_widths = [], [], []
    currency_mask = "#{I18n.t('number.currency.format.unit')}%.2f"

    column_order.each do |col_name, col_width|
      column_headers << ResourceUtilization.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_width)
    end

    self.resource_utilizations.each do |resource_utilization|
      column_data << [
        resource_utilization.resource.resource_name,
        resource_utilization.units,
        currency_mask % resource_utilization.cost_per_unit,
        currency_mask % resource_utilization.cost
      ]
    end

    column_data << [
      '', '', '', "<b>#{currency_mask % self.cost}</b>"
    ]

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
