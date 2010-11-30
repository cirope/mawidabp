class Workflow < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_validation :set_proper_parent
  before_destroy :can_be_destroyed?

  # Atributos no persistentes
  attr_accessor :allow_overload, :new_version
  attr_writer :cost

  attr_readonly :period_id, :review_id

  # Restricciones
  validates :period_id, :review_id, :presence => true
  validates_uniqueness_of :review_id, :allow_nil => true, :allow_blank => true
  validates_numericality_of :period_id, :review_id, :only_integer => true,
    :allow_nil => true, :allow_blank => true
  validate :check_if_is_frozen

  # Relaciones
  belongs_to :period
  belongs_to :review
  has_one :organization, :through => :period
  has_one :plan_item, :through => :review

  has_many :workflow_items, :dependent => :destroy,
    :order => [
      "#{WorkflowItem.table_name}.order_number ASC",
      "#{WorkflowItem.table_name}.start ASC",
      "#{WorkflowItem.table_name}.end ASC"
    ].join(', ')
  has_many :resource_utilizations, :through => :workflow_items

  accepts_nested_attributes_for :workflow_items, :allow_destroy => true

  def initialize(attributes = nil)
    super(attributes)

    self.period ||= Period.currents.first
  end

  def set_proper_parent
    self.workflow_items.each { |wi| wi.workflow = self }
  end

  def overloaded?
    self.workflow_items.any? { |wi| wi.overloaded }
  end

  def allow_overload?
    self.allow_overload == true || (self.allow_overload.respond_to?(:to_i) &&
      self.allow_overload.to_i != 0)
  end

  def check_if_is_frozen
    unless self.is_frozen? && self.changed?
      true
    else
      msg = I18n.t(:'workflow.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

      false
    end
  end

  def can_be_destroyed?
    !self.is_frozen?
  end

  def is_frozen?
    self.review.try(:is_frozen?)
  end

  def begining
    self.workflow_items.sort do |wi1, wi2|
      (wi1.start || Date.today) <=> (wi2.start || Date.today)
    end.first.try(:start) || Date.today
  end

  def ending
    self.workflow_items.sort do |wi1, wi2|
      (wi1.end || Date.today) <=> (wi2.end || Date.today)
    end.last.try(:end) || Date.today
  end

  def to_pdf(organization = nil, include_details = true)
    pdf = PDF::Writer.create_generic_pdf :landscape
    currency_mask = "#{I18n.t(:'number.currency.format.unit')}%.2f"
    column_order = ['order_number', 'task', 'start', 'end', 'predecessors',
      'resources']
    columns = {}
    column_data = []

    pdf.add_generic_report_header organization

    pdf.add_title "#{Workflow.model_name.human}\n", (PDF_FONT_SIZE * 1.25).round,
      :center

    pdf.add_description_item Workflow.human_attribute_name('review_id'),
      self.review.to_s, 0, false

    pdf.add_description_item(I18n.t(:'workflow.period.title',
        :number => self.period.number), I18n.t(:'workflow.period.range',
        :from_date => I18n.l(self.period.start, :format => :long),
        :to_date => I18n.l(self.period.end, :format => :long)), 0, false)

    column_order.each do |col_name|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |column|
        column.heading = WorkflowItem.human_attribute_name(col_name)
      end
    end

    self.workflow_items.each do |workflow_item|
      resource_text = currency_mask % workflow_item.cost
      column_data << {
        'order_number' => workflow_item.order_number,
        'task' => workflow_item.task.to_iso,
        'start' => I18n.l(workflow_item.start, :format => :default),
        'end' => I18n.l(workflow_item.end, :format => :default),
        'predecessors' => workflow_item.predecessors.to_a.to_sentence,
        'resources' => workflow_item.cost > 0 && include_details ?
          ("<c:ilink dest='workflow_cost_detail_#{workflow_item.id}'>" +
            "#{resource_text}</c:ilink>") : resource_text
      }
    end

    column_data << {
      'order_number' => '', 'task' => '', 'start' => '', 'end' => '',
      'predecessors' => '', 'resources' => "<b>#{currency_mask % self.cost}</b>"
    }

    unless column_data.blank?
      pdf.move_pointer PDF_FONT_SIZE
      
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_width - pdf.right_margin - pdf.left_margin
        table.columns = columns
        table.data = column_data
        table.column_order = column_order
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

    if include_details &&
        !self.workflow_items.all? { |wi| wi.resource_utilizations.blank? }
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title I18n.t(:'workflow.pdf.resources_utilization'),
        (PDF_FONT_SIZE * 1.25).round

      self.workflow_items.each do |workflow_item|
        unless workflow_item.resource_utilizations.blank?
          workflow_item.add_resource_data(pdf)
        end
      end
    end

    if include_details && !self.review.plan_item.resource_utilizations.blank?
      pdf.move_pointer PDF_FONT_SIZE

      pdf.add_title I18n.t(:'workflow.pdf.planned_resources_utilization'),
        (PDF_FONT_SIZE * 1.25).round
      
      self.review.plan_item.add_resource_data(pdf, false)

      pdf.move_pointer((PDF_FONT_SIZE * 0.5).round)

      pdf.text I18n.t(:'workflow.pdf.planned_resources_utilization_explanation'),
        :font_size => (PDF_FONT_SIZE * 0.75).round
    end

    pdf.custom_save_as(self.pdf_name, Workflow.table_name, self.id)
  end

  def absolute_pdf_path
    PDF::Writer.absolute_path(self.pdf_name, Workflow.table_name, self.id)
  end

  def relative_pdf_path
    PDF::Writer.relative_path(self.pdf_name, Workflow.table_name, self.id)
  end

  def pdf_name
    I18n.t :'workflow.pdf.pdf_name',
      :review => self.review.sanitized_identification
  end

  def cost
    self.workflow_items.to_a.sum(&:cost)
  end

  def human_unit_cost
    self.workflow_items.to_a.sum(&:human_unit_cost)
  end
end