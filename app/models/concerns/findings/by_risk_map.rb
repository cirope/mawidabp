module Findings::ByRiskMap
  extend ActiveSupport::Concern

  OPTIONS = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

  def risk_map_row options = {}
    [
      organization,
      organization_id,
      review.identification,
      title,
      [organization.name,review.identification,review_code].join,
      taggings_findings('finding'),
      taggings_findings('review'),
      control_objective_item_id,
      control_objective_item.control_objective_text,
      control_objective_item.relevance,
      control_objective_item.review.id,
      control_objective_item.design_score,
      control_objective_item.sustantive_score,
      control_objective_item.compliance_score,
      average_scores.to_f,
      id,
      description,
      review_code,
      risk,
      try(:risk_text) || '',
      custom_state_text(options),
      state,
      origination_date,
      follow_up_date,
      updated_at,
      solution_date,
      priority,
      parent_id,
      repeated_of_id,
      antiquity_finding(options),
      pending_finding_to(options),
      new_finding_between_committee_dates(options),
      closed_finding_between_committee_dates(options),
      business_unit_type.external,
      business_unit.name,
      control_objective_item.best_practice.description,
      control_objective_item.best_practice.name,
      control_objective_item.best_practice.id,
      process_control.name,
      process_control.id
    ]
  end

  private

    def custom_state_text options
      if state == Finding::STATUS[:being_implemented]
        current_committee_date = options['current_committee_date'].to_date

        if origination_date && current_committee_daate
          origination_date > current_committee_date ? 'EPI_Vigente' : 'EPI_Vencida'
        else
          state_text
        end
      end
    end

    def taggings_findings kind
      tags = taggings.includes(:tag).where(tag: {kind: kind}).pluck(:name)

      tags.join(' - ')
    end

    def antiquity_finding options
      current_committee_date = options['current_committee_date'].to_date

      if origination_date && current_committee_date.present?
        (current_committee_date - origination_date).to_i
      else
        '-'
      end
    end

    def pending_finding_to options
      antiquity = antiquity_finding(options).to_i
      days      = options['days'].to_i

      antiquity > days ? '1' : '0'
    end

    def new_finding_between_committee_dates options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date
      exclude_state         = Finding::STATUS[:repeated]

      if committee_dates_present? options
        if origination_date && state != exclude_state &&
            (origination_date > before_committee_date && origination_date <= current_committee_date)
          '1'
        else
          '0'
        end
      else
        '-'
      end
    end

    def closed_finding_between_committee_dates options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date
      allowed_state          = state == Finding::STATUS[:implemented_audited]

      if committee_dates_present? options
        if allowed_state && (updated_at > before_committee_date && updated_at <= current_committee_date)
          '1'
        else
          '0'
        end
      else
        '-'
      end
    end

    def committee_dates_present? options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date

      before_committee_date.present? && current_committee_date.present? ? true : false
    end

    def average_scores
      (control_objective_item.design_score.to_i +
        control_objective_item.sustantive_score.to_i +
        control_objective_item.compliance_score.to_i) / 3
    end

  module ClassMethods

    def by_risk_map options
      prefix_header_name = 'follow_up_committee_report.weaknesses_risk_map'

      csv_str = CSV.generate(**OPTIONS) do |csv|
        csv << risk_map_column_headers(prefix_header_name)
      end

      ChunkIterator.iterate all_with_inclusions do |cursor|
        csv_str += CSV.generate(**OPTIONS) do |csv|
          cursor.each { |f| csv << f.risk_map_row(options) }
        end
      end

      "\uFEFF#{csv_str}"
    end

    private

      def risk_map_column_headers prefix
        [
          'organization',
          'organization_id',
          'identification',
          'title',
          'review_identification',
          'finding_tags',
          'review_tags',
          'control_objective_item_id',
          'control_objective_item_control_objective_text',
          'control_objective_item_relevance',
          'control_objective_item_review_id',
          'control_objective_item_design_score',
          'control_objective_item_sustantive_score',
          'control_objective_item_compliance_score',
          'average_score',
          'finding_id',
          'finding_description',
          'finding_review_code',
          'finding_risk',
          'finding_risk_level',
          'status',
          'finding_state',
          'finding_origination_date',
          'finding_follow_up_date',
          'finding_updated_at',
          'finding_solution_date',
          'finding_priority',
          'finding_parent_id',
          'finding_repeated_of_id',
          'finding_antiquity',
          'old_data',
          'new_finding',
          'closed_finding',
          'business_unit_external',
          'business_unit_name',
          'best_practice_description',
          'best_practice_name',
          'best_practice_id',
          'process_control_name',
          'process_control_id'
        ]
      end
  end
end
