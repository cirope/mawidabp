class ConclusionFinalReview < ConclusionReview
  include ConclusionFinalReviews::Defaults
  include ConclusionFinalReviews::Destroy
  include ConclusionFinalReviews::Scopes
  include ConclusionFinalReviews::Search
  include ConclusionFinalReviews::Sort
  include ConclusionFinalReviews::Validations

  # Callbacks
  before_create :check_if_can_be_created,
                :sort_findings_if_apply,
                :recalculate_score,
                :duplicate_review_findings,
                :assign_audit_date_to_control_objective_items

  # Restricciones de los atributos
  attr_readonly :issue_date, :close_date, :conclusion, :applied_procedures

  # Relaciones
  has_one :conclusion_draft_review, through: :review

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

  def sort_findings_if_apply
    if method = sort_findings_by_method
      review.send method
      review.reload
    end
  end

  def recalculate_score
    unless WEAKNESS_SCORE_OBSOLESCENCE == 0
      review.score_array date: issue_date
      review.save!
    end
  end

  def duplicate_review_findings
    findings = Finding.list
                      .left_joins(:control_objective_item)
                      .where(control_objective_items: { review_id: review_id }, final: false)
                      .where.not(state: Finding::STATUS[:revoked])
                      .order(:order_number, :id)

    last_code = latest_final_weakness_review_code if Current.global_weakness_code

    begin
      findings.all? do |finding|
        final_finding = finding.dup
        final_finding.final = true
        final_finding.parent = finding
        final_finding.skip_work_paper = finding.skip_work_paper = true
        final_finding.origination_date ||= finding.origination_date ||= self.issue_date

        if finding.repeated_of
          final_finding.first_follow_up_date ||=
            finding.first_follow_up_date     ||=
            finding.follow_up_date
        else
          final_finding.first_follow_up_date =
            finding.first_follow_up_date     =
            finding.follow_up_date
        end

        final_finding.build_image_model(
          image: File.open(finding.image_model.image.path)
        ) if finding.respond_to?(:image_model) && finding.image_model

        finding.business_unit_findings.each do |buf|
          final_finding.business_unit_findings.build(
            buf.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.finding_user_assignments.each do |fua|
          final_finding.finding_user_assignments.build(
            fua.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.issues.each do |i|
          final_finding.issues.build(
            i.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.tasks.each do |t|
          final_finding.tasks.build(
            t.attributes.dup.merge('id' => nil, 'finding_id' => nil)
          )
        end

        finding.taggings.each do |t|
          final_finding.taggings.build(
            t.attributes.dup.merge('id' => nil, 'taggable_id' => nil)
          )
        end

        finding.work_papers.each do |wp|
          final_finding.work_papers.build(
            wp.attributes.dup.merge('id' => nil)
          ).check_code_prefix = false
        end

        unless finding.review_code.size == 8 && finding.draft_review_code.blank?
          final_finding.draft_review_code ||= finding.draft_review_code ||= finding.review_code
        end

        if Current.global_weakness_code && finding.kind_of?(Weakness)
          if finding.repeated_of.present?
            code = finding.repeated_of.review_code
          else
            if finding.review_code.size == 8 && !review_code_final_exist?(finding.review_code)
              code = finding.review_code
            else
              code = last_code = last_code.next
            end
          end

          final_finding.review_code = finding.review_code = code
        end

        final_finding.save!
        finding.save!
      end

      revoked_findings = self.review.weaknesses.revoked + self.review.oportunities.revoked

      revoked_findings.each do |rf|
        rf.final = true

        unless rf.review_code.size == 8 && rf.draft_review_code.blank?
          rf.draft_review_code ||= rf.review_code
        end

        rf.save! validate: false
      end
    rescue ActiveRecord::RecordInvalid => ex
      errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

      Rails.logger.error ex.inspect
      raise ActiveRecord::Rollback
    end
  end

  def review_code_final_exist? code
    Weakness.list.finals(true).where(review_code: code).exists?
  end

  def last_final_weakness
    Weakness.list.finals(true).not_revoked.reorder(review_code: :desc).first
  end

  def latest_final_weakness_review_code
    prefix         = I18n.t 'code_prefixes.weaknesses'
    last_used_code = last_final_weakness&.review_code || '0'
    number_code    = last_used_code.match(/\d+\Z/).to_a.first.to_i

    "#{prefix}#{'%.7d' % number_code}".strip
  end

  def assign_audit_date_to_control_objective_items
    if DISABLE_COI_AUDIT_DATE_VALIDATION
      begin
        review.control_objective_items.each do |coi|
          if coi.audit_date.blank?
            coi.creating_final_review = true

            coi.update! audit_date: issue_date
          end
        end
      rescue ActiveRecord::RecordInvalid => ex
        errors.add :base, I18n.t('conclusion_final_review.stale_object_error')

        Rails.logger.error ex.inspect
        raise ActiveRecord::Rollback
      end
    end
  end

  def is_frozen?
    close_date && Time.zone.today > close_date
  end

  def all_close_dates
    all_close_dates = []
    last_date       = close_date

    dates = versions.map do |v|
      v.reify&.close_date
    end

    dates.reverse.each do |d|
      if d.present? && last_date && d < last_date
        all_close_dates << last_date = d
      end
    end
  end

  private

    def check_if_can_be_created
      throw :abort unless check_for_approval
    end

    def sort_findings_by_method
      methods = JSON.parse ENV['AUTOMATICALLY_SORT_FINDINGS_ON_CONCLUSION'] || '{}'

      methods[organization.prefix] if organization && methods.present?
    end
end
