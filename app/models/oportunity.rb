class Oportunity < Finding
  # Named scopes
  named_scope :all_for_report,
    :conditions => {
      :state => STATUS.except(*EXCLUDE_FROM_REPORTS_STATUS).values,
      :final => true
    },
    :order => 'state ASC'

  # Restricciones
  validates_each :review_code do |record, attr, value|
    prefix = record.get_parameter(:admin_code_prefix_for_oportunities, false,
      record.control_objective_item.try(:review).try(:organization).try(:id))
    regex = Regexp.new "\\A#{prefix}\\d+\\Z"

    record.errors.add attr, :invalid unless value =~ regex
  end
  
  def initialize(attributes = nil, import_users = false)
    super(attributes, import_users)

    self.review_code ||= self.control_objective_item.try(:review).try(
      :next_oportunity_code, self.prefix)
  end

  def self.columns_for_sort
    Finding.columns_for_sort.except(:risk_asc, :risk_desc)
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix = self.get_parameter(
      :admin_code_prefix_for_work_papers_in_oportunities)
    work_paper.neighbours =
      (self.control_objective_item.try(:review).try(:work_papers) || []) +
      self.work_papers.reject { |wp| wp == work_paper }
  end

  def prefix
    self.control_objective_item.try(:review) ?
      self.get_parameter(:admin_code_prefix_for_oportunities, false,
      self.control_objective_item.review.organization.id) : nil
  end
end