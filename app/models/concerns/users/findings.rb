module Users::Findings
  extend ActiveSupport::Concern

  included do
    has_many :finding_user_assignments
    has_many :findings, -> { uniq }, through: :finding_user_assignments,
      source: :raw_finding, class_name: 'Finding'
    has_many :weaknesses, -> { uniq }, through: :finding_user_assignments,
      source_type: 'Weakness', source: :finding
    has_many :oportunities, -> { uniq }, through: :finding_user_assignments,
      source_type: 'Oportunity', source: :finding
  end

  def has_pending_findings?
    findings.all_for_reallocation.present?
  end
end
