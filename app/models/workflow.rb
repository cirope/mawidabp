class Workflow < ApplicationRecord
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  before_validation :set_proper_parent
  before_destroy :check_if_can_be_destroyed

  # Atributos no persistentes
  attr_accessor :allow_overload

  attr_readonly :period_id, :review_id

  # Scopes
  scope :list, -> { where(organization_id: Organization.current_id) }

  # Restricciones
  validates :period_id, :review_id, :organization_id, presence: true
  validates :review_id, uniqueness: true, allow_nil: true,
    allow_blank: true
  validates :period_id, :review_id, numericality: {only_integer: true},
    allow_nil: true, allow_blank: true
  validate :check_if_is_frozen

  # Relaciones
  belongs_to :period
  belongs_to :review
  belongs_to :organization
  has_one :plan_item, through: :review

  has_many :workflow_items, -> {
    order(
      "#{WorkflowItem.quoted_table_name}.#{WorkflowItem.qcn('order_number')} ASC",
      "#{WorkflowItem.quoted_table_name}.#{WorkflowItem.qcn('start')} ASC",
      "#{WorkflowItem.quoted_table_name}.#{WorkflowItem.qcn('end')} ASC"
    )
  }, dependent: :destroy
  has_many :resource_utilizations, through: :workflow_items

  accepts_nested_attributes_for :workflow_items, allow_destroy: true

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
    if self.is_frozen? && self.changed?
      msg = I18n.t('workflow.readonly')
      self.errors.add(:base, msg) unless self.errors.full_messages.include?(msg)

      false
    else
      true
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
    pdf = Prawn::Document.create_generic_pdf :landscape
    column_order = [
      ['order_number', 10], ['task', 60], ['start', 10], ['end', 10],
      ['resources', 10]
    ]
    column_data, column_headers, column_widths = [], [], []

    pdf.add_generic_report_header organization

    pdf.add_title "#{Workflow.model_name.human}\n", (PDF_FONT_SIZE * 1.25).round,
      :center

    pdf.add_description_item Workflow.human_attribute_name(:review_id),
      self.review.to_s, 0, false

    pdf.add_description_item(I18n.t('workflow.period.title',
        name: self.period.name), I18n.t('workflow.period.range',
        from_date: I18n.l(self.period.start, format: :long),
        to_date: I18n.l(self.period.end, format: :long)), 0, false)

    column_order.each do |col_name|
      column_headers << WorkflowItem.human_attribute_name(col_name.first)
      column_widths << pdf.percent_width(col_name.last)
    end

    column_data[0] = column_headers

    self.workflow_items.sort_by(&:order_number).each do |workflow_item|
      resource_text = '%.2f' % workflow_item.units
      column_data[workflow_item.order_number] = [
        workflow_item.order_number,
        workflow_item.task,
        I18n.l(workflow_item.start, format: :default),
        I18n.l(workflow_item.end, format: :default),
        resource_text
      ]
    end

    column_data << [
      '', '', '', '', "<b>#{'%.2f' % units}</b>"
    ]

    unless column_data.blank?
      pdf.move_down PDF_FONT_SIZE
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data, table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    if include_details &&
        !self.workflow_items.all? { |wi| wi.resource_utilizations.blank? }
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title I18n.t('workflow.pdf.resources_utilization'),
        (PDF_FONT_SIZE * 1.25).round

      self.workflow_items.sort_by(&:order_number).each do |workflow_item|
        unless workflow_item.resource_utilizations.blank?
          workflow_item.add_resource_data(pdf)
        end
      end
    end

    if include_details && !self.review.plan_item.resource_utilizations.blank?
      pdf.move_down PDF_FONT_SIZE

      pdf.add_title I18n.t('workflow.pdf.planned_resources_utilization'),
        (PDF_FONT_SIZE * 1.25).round

      self.review.plan_item.add_resource_data(pdf, false)

      pdf.move_down((PDF_FONT_SIZE * 0.5).round)

      pdf.text I18n.t('workflow.pdf.planned_resources_utilization_explanation'),
        font_size: (PDF_FONT_SIZE * 0.75).round
    end

    pdf.custom_save_as(self.pdf_name, Workflow.table_name, self.id)
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path(self.pdf_name, Workflow.table_name, self.id)
  end

  def relative_pdf_path
    Prawn::Document.relative_path(self.pdf_name, Workflow.table_name, self.id)
  end

  def pdf_name
    I18n.t 'workflow.pdf.pdf_name',
      review: self.review.sanitized_identification
  end

  def human_units
    workflow_items.to_a.sum &:human_units
  end

  def material_units
    workflow_items.to_a.sum &:material_units
  end

  def units
    workflow_items.map(&:units).compact.sum
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end
end
