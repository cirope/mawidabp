class ConclusionFinalReview < ConclusionReview
  # Constantes
  COLUMNS_FOR_SEARCH = {
    close_date: {
      column: "#{table_name}.#{qcn('close_date')}",
      operator: SEARCH_ALLOWED_OPERATORS.values, mask: "%s",
      conversion_method: lambda { |value|
        Timeliness.parse(value, :date).to_s(:db)
      },
      regexp: SEARCH_DATE_REGEXP
    }
  }.merge(GENERIC_COLUMNS_FOR_SEARCH).with_indifferent_access

  # Named scopes
  scope :list_all_by_date, ->(from_date, to_date) {
    list.includes(
      review: [
        { plan_item: { business_unit: :business_unit_type } }
      ]
    ).where(
      'issue_date BETWEEN :from_date AND :to_date',
      from_date: from_date, to_date: to_date
    ).references(:business_unit_types).order(
      [
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
        'issue_date ASC'
      ]
    )
  }
  scope :list_all_by_solution_date, ->(from_date, to_date) {
    list.includes(
      review: [
        { plan_item: { business_unit: :business_unit_type } },
        { control_objective_items: :weaknesses }
      ]
    ).where(
      "#{Weakness.quoted_table_name}.#{Weakness.qcn('solution_date')} BETWEEN :from_date AND :to_date",
      from_date: from_date, to_date: to_date
    ).references(:findings, :business_unit_types).order(
      [
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
        'issue_date ASC'
      ]
    )
  }
  scope :list_all_by_final_solution_date, ->(from_date, to_date) {
    list.includes(
      review: [
        { plan_item: { business_unit: :business_unit_type } },
        { control_objective_items: :final_weaknesses }
      ]
    ).where(
      "#{Weakness.quoted_table_name}.#{Weakness.qcn('solution_date')} BETWEEN :from_date AND :to_date",
      from_date: from_date, to_date: to_date
    ).references(:findings, :business_unit_types).order(
      [
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
        'issue_date ASC'
      ]
    )
  }
  scope :internal_audit, -> {
    includes(
      review: {plan_item: {business_unit: :business_unit_type}}
    ).where("#{BusinessUnitType.table_name}.external" => false).references(
      :business_unit_types
    )
  }
  scope :external_audit, -> {
    includes(
      review: {plan_item: {business_unit: :business_unit_type}}
    ).where("#{BusinessUnitType.table_name}.external" => true).references(
      :business_unit_types
    )
  }
  scope :next_to_expire, -> {
    where(
      'close_date = :warning_date',
      warning_date:
        CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS.days.from_now_in_business.to_date
    )
  }

  # Callbacks
  before_save :check_for_approval
  before_create :duplicate_review_findings

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Restricciones
  validates :close_date, :conclusion, presence: true
  validates :review_id, uniqueness: true, allow_blank: true,
    allow_nil: true
  validates_date :close_date, allow_nil: true, allow_blank: true,
    on: :create, on_or_after: lambda { |conclusion_review|
      conclusion_review.issue_date || Date.today
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
  has_one :conclusion_draft_review, through: :review
  has_many :polls, as: :pollable

  def self.columns_for_sort
    ConclusionReview.columns_for_sort.dup.merge(
      close_date: {
        name: ConclusionReview.human_attribute_name(:close_date),
        field: "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('close_date')} ASC"
      }
    )
  end

  def initialize(attributes = nil, options = {}, import_from_draft = true)
    super(attributes, options)

    if import_from_draft && self.review
      draft = ConclusionDraftReview.where(review_id: self.review_id).first

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
    findings = self.review.weaknesses.not_revoked + self.review.oportunities.not_revoked +
      self.review.nonconformities.not_revoked + self.review.potential_nonconformities.not_revoked +
      self.review.fortresses
    all_created = false

    begin
      findings.all? do |f|
        finding = f.dup
        finding.final = true
        finding.parent = f
        finding.origination_date ||= f.origination_date ||= self.issue_date

        f.finding_user_assignments.each do |fua|
          finding.finding_user_assignments.build(
            fua.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        f.work_papers.each do |wp|
          finding.work_papers.build(
            wp.attributes.dup.merge('id' => nil)
          ).check_code_prefix = false
        end

        finding.save!
        f.save!
      end

      revoked_findings = self.review.weaknesses.revoked + self.review.oportunities.revoked +
        self.review.nonconformities.revoked + self.review.potential_nonconformities.revoked

      revoked_findings.each { |rf| rf.final = true; rf.save! }

      all_created = true
    rescue ActiveRecord::RecordInvalid
      raise ActiveRecord::Rollback
    end

    if all_created
      true
    else
      self.errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

      false
    end
  end

  def is_frozen?
    self.close_date && Date.today > self.close_date
  end

  def self.warning_auditors_about_close_date
    wday = Date.today.wday

    # Sólo si no es sábado o domingo (porque no tiene sentido)
    unless [0, 6].include? wday
      # Si es viernes notifico también los que cierran el fin de semana
      if wday == 5
        cfrs = ConclusionFinalReview.where(
          'close_date BETWEEN :from AND :to',
          from: CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS.days.from_now_in_business.to_date,
          to: (CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS + 2).days.from_now_in_business.to_date
        )
      else
        cfrs = ConclusionFinalReview.next_to_expire
      end

      if cfrs.present?
        cfrs.each do |cfr|
          ruas = cfr.review.review_user_assignments
          ruas.each do |rua|
            # si no es gerente o auditado
            unless rua.assignment_type == 2 || rua.assignment_type == -1
              NotifierMailer.delay.conclusion_final_review_expiration_warning(rua.user, cfr)
            end
          end
        end
      end
    end
  end
end
