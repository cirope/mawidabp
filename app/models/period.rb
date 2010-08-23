class Period < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Callbacks
  before_destroy :can_be_destroyed?
  
  # Named scopes
  named_scope :list, lambda {
    {
      :conditions => {
        :organization_id => GlobalModelConfig.current_organization_id
      },
      :order => 'number DESC'
    }
  }
  named_scope :list_by_date, lambda { |from_date, to_date|
    {
      :conditions => [
        [
          "#{table_name}.organization_id = :organization_id",
          [
            "#{table_name}.start BETWEEN :from_date AND :to_date",
            "#{table_name}.end BETWEEN :from_date AND :to_date"
          ].join(' OR ')
        ].map {|c| "(#{c})"}.join(' AND '),
        {
          :from_date => from_date,
          :to_date => to_date,
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => ["#{table_name}.start ASC", "#{table_name}.end ASC"].join(', ')
    }
  }
  named_scope :currents, lambda {
    {
      :conditions => [
        [
          'organization_id = :organization_id',
          "#{table_name}.start <= :today",
          "#{table_name}.end >= :today"
        ].join(' AND '), {
          :organization_id => GlobalModelConfig.current_organization_id,
          :today => Date.today
        }
      ],
      :order => ["#{table_name}.start ASC", "#{table_name}.end ASC"].join(', ')
    }
  }
  named_scope :list_all_without_plans, lambda {
    {
      :include => :plans,
      :conditions => [
        [
          "#{table_name}.organization_id = :organization_id",
          "#{Plan.table_name}.period_id IS NULL"
        ].join(' AND '),
        {
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => ["#{table_name}.start ASC", "#{table_name}.end ASC"].join(', ')
    }
  }
  named_scope :list_all_without_procedure_controls, lambda {
    {
      :include => :procedure_controls,
      :conditions => [
        [
          "#{table_name}.organization_id = :organization_id",
          "#{ProcedureControl.table_name}.period_id IS NULL"
        ].join(' AND '),
        {
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => ["#{table_name}.start ASC", "#{table_name}.end ASC"].join(', ')
    }
  }

  
  # Restricciones
  validates_numericality_of :number, :only_integer => true, :allow_nil => true
  validates_presence_of :number, :start, :end, :description, :organization_id
  validates_uniqueness_of :number, :scope => :organization_id
  validates_date :start, :allow_nil => true, :allow_blank => true
  validates_date :end, :allow_nil => true, :allow_blank => true,
    :after => :start
  
  # Relaciones
  belongs_to :organization
  has_many :reviews
  has_many :plans
  has_many :workflows
  has_many :procedure_controls

  def <=>(other)
    self.id <=> other.id
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
      errors << I18n.t(:'period.errors.has_reviews', :count => self.reviews.size)
    end

    unless self.plans.empty?
      errors << I18n.t(:'period.errors.has_plans', :count => self.plans.size)
    end

    unless self.workflows.empty?
      errors << I18n.t(:'period.errors.has_workflows',
        :count => self.workflows.size)
    end

    unless self.procedure_controls.empty?
      errors << I18n.t(:'period.errors.has_procedure_controls',
        :count => self.procedure_controls.size)
    end

    errors.each { |e| self.errors.add_to_base e unless self.errors.include?(e) }

    errors.blank?
  end
end