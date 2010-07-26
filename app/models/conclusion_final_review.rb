class ConclusionFinalReview < ConclusionReview
  # Named scopes
  named_scope :list_all_by_date, lambda { |from_date, to_date|
    {
      :include => {
        :review => [:period, {:control_objective_items => :weaknesses},
          {:plan_item => {:business_unit => :business_unit_type}}]
      },
      :conditions => [
        [
          "#{Period.table_name}.organization_id = :organization_id",
          'issue_date BETWEEN :from_date AND :to_date'
        ].join(' AND '),
        {
          :from_date => from_date, :to_date => to_date,
          :organization_id => GlobalModelConfig.current_organization_id
        }
      ],
      :order => [
        "#{BusinessUnitType.table_name}.external ASC",
        "#{BusinessUnitType.table_name}.name ASC",
        'issue_date ASC'
      ].join(', ')
    }
  }
  named_scope :internal_audit,
    :include => {
      :review => {:plan_item => {:business_unit => :business_unit_type}}
    },
    :conditions => { "#{BusinessUnitType.table_name}.external" => false }
  named_scope :external_audit,
    :include => {
      :review => {:plan_item => {:business_unit => :business_unit_type}}
    },
    :conditions => { "#{BusinessUnitType.table_name}.external" => true }

  # Callbacks
  before_save :check_for_approval
  before_create :duplicate_review_findings

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Restricciones
  validates_presence_of :close_date
  validates_uniqueness_of :review_id, :allow_blank => true, :allow_nil => true
  validates_date :close_date, :allow_nil => true, :on => :create,
    :on_or_after => lambda { |conclusion_review|
      conclusion_review.issue_date || Time.now.to_date
    }
  validates_each :review_id do |record, attr, value|
    if record.review && record.review.conclusion_draft_review
      unless record.review.conclusion_draft_review.approved?
        record.errors.add attr, :invalid
      end
    elsif record.review
      record.errors.add attr, :without_draft
    end
  end

  # Relaciones
  has_one :conclusion_draft_review, :through => :review

  def initialize(attributes = nil, import_from_draft = true)
    super(attributes)

    if import_from_draft && self.review
      draft = ConclusionDraftReview.first(:conditions =>
          {:review_id => self.review_id}, :order => 'created_at DESC')

      self.attributes = draft.attributes if draft
    end
  end

  def check_for_approval
    self.approved = self.review && (self.review.is_approved? ||
        (self.review.can_be_approved_by_force &&
          self.review.conclusion_draft_review.try(:approved)))

    if self.approved?
      true
    else
      self.errors.add :review_id, :invalid

      false
    end
  end

  def duplicate_review_findings
    findings = self.review.weaknesses + self.review.oportunities
    all_created = false

    Finding.transaction do
      begin
        findings.all? do |f|
          finding = f.clone

          finding.final = true
          finding.parent = f
          finding.user_ids = f.user_ids
          
          f.work_papers.each do |wp|
            finding.work_papers.build(wp.attributes.clone.update(:id => nil)).check_code_prefix = false
          end

          finding.save!
          f.save!
        end

        all_created = true
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end

    if all_created
      true
    else
      self.errors.add_to_base(
        I18n.t(:'conclusion_final_review.stale_object_error'))

      false
    end
  end

  def is_frozen?
    self.close_date && Time.now.to_date > self.close_date
  end
end