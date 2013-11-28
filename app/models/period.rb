class Period < ActiveRecord::Base
  include ParameterSelector
  include Comparable
  include PaperTrail::DependentDestroy

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Callbacks
  #before_destroy :can_be_destroyed?

  # Named scopes
  scope :list, -> { where(organization_id: Organization.current_id).order('number DESC') }
  scope :list_by_date, ->(from_date, to_date) {
    list.where(
      [
        "#{table_name}.start BETWEEN :from_date AND :to_date",
        "#{table_name}.end BETWEEN :from_date AND :to_date"
      ].join(' OR '), { :from_date => from_date, :to_date => to_date }
    ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"])
  }
  scope :currents, -> {
    list.where(
      [
        "#{table_name}.start <= :today",
        "#{table_name}.end >= :today"
      ].join(' AND '), { :today => Date.today }
    ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"])
  }
  scope :list_all_without_plans, -> {
    list.includes(:plans).where(
      "#{Plan.table_name}.period_id IS NULL"
    ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"]).references(
      :plans
    )
  }
  scope :list_all_without_procedure_controls, -> {
    list.includes(:procedure_controls).where(
      "#{ProcedureControl.table_name}.period_id IS NULL"
    ).order(["#{table_name}.start ASC", "#{table_name}.end ASC"]).references(
      :procedure_controls
    )
  }

  # Restricciones
  validates :number, :numericality => {:only_integer => true},
    :allow_nil => true
  validates :number, :start, :end, :description, :organization_id,
    :presence => true
  validates :number, :uniqueness => {:scope => :organization_id}
  validates_date :start, :allow_nil => true, :allow_blank => true
  validates_date :end, :allow_nil => true, :allow_blank => true,
    :after => :start

  # Relaciones
  belongs_to :organization
  has_many :reviews, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :workflows, dependent: :destroy
  has_many :procedure_controls, dependent: :destroy

  def <=>(other)
    start_result = self.start <=> other.start
    end_result = self.end <=> other.end if start_result == 0

    end_result || start_result
  end

  def to_s
    "#{self.description} (#{self.number})"
  end

  def inspect
    "#{self.number} (#{self.dates_range_text})"
  end

  def dates_range_text(short = true)
    start_text = I18n.l self.start, :format => (short ? :minimal : :long)
    end_text = I18n.l self.end, :format => (short ? :minimal : :long)
    start_label = Period.human_attribute_name('start')
    end_label = Period.human_attribute_name('end')

    short ?
      "#{start_text} -> #{end_text}" :
      "#{start_label}: #{start_text} | #{end_label}: #{end_text}"
  end

  def can_be_destroyed?
    errors = []

    unless self.reviews.empty?
      errors << I18n.t('period.errors.has_reviews', :count => self.reviews.size)
    end

    unless self.plans.empty?
      errors << I18n.t('period.errors.has_plans', :count => self.plans.size)
    end

    unless self.workflows.empty?
      errors << I18n.t('period.errors.has_workflows',
        :count => self.workflows.size)
    end

    unless self.procedure_controls.empty?
      errors << I18n.t('period.errors.has_procedure_controls',
        :count => self.procedure_controls.size)
    end

    errors.each { |e| self.errors.add(:base, e) unless self.errors.include?(e) }

    errors.blank?
  end

  def contains?(date)
    date.respond_to?(:between?) && date.between?(self.start, self.end)
  end
end
