module Users::Findings
  extend ActiveSupport::Concern

  included do
    has_many :finding_user_assignments
    has_many :findings, through: :finding_user_assignments,
      source: :raw_finding, class_name: 'Finding'
    has_many :weaknesses, through: :finding_user_assignments,
      source_type: 'Weakness', source: :finding
    has_many :oportunities, through: :finding_user_assignments,
      source_type: 'Oportunity', source: :finding
    has_many :tasks, through: :findings
  end

  def has_pending_findings?
    findings.all_for_reallocation.present?
  end
end
