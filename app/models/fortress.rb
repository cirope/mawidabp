class Fortress < Finding
  # Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, lambda {
    where(
      :final => true
    )
  }

  # Restricciones
  validates_each :review_code do |record, attr, value|
    prefix = record.get_parameter(:admin_code_prefix_for_fortresses, false,
      record.control_objective_item.try(:review).try(:organization).try(:id))
    regex = /\A#{prefix}\d+\Z/

    record.errors.add attr, :invalid unless value =~ regex
  end

  def initialize(attributes = nil, options = {}, import_users = false)
    super(attributes, options, import_users)

    self.review_code ||= self.next_code
    self.state = nil
  end

  def self.columns_for_sort
    Finding.columns_for_sort.except(
      :risk_asc, :risk_desc, :follow_up_date_asc, :follow_up_date_desc, :state
    )
  end

  def prepare_work_paper(work_paper)
    work_paper.code_prefix = self.get_parameter(
      :admin_code_prefix_for_work_papers_in_fortresses
    )
  end

  def last_work_paper_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)
    code_prefix = self.parameter_in(GlobalModelConfig.current_organization_id,
      :admin_code_prefix_for_work_papers_in_fortresses, review.try(:created_at))

    code_from_review = review ?
      review.last_fortress_work_paper_code(code_prefix) :
      "#{code_prefix} 0".strip

    code_from_fortress = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_fortress].compact.max
  end

  def prefix
    self.control_objective_item.try(:review) ?
      self.get_parameter(:admin_code_prefix_for_fortresses, false,
      self.control_objective_item.review.organization.id) : nil
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.try(:reload).try(:review)
    code_prefix = self.parameter_in(GlobalModelConfig.current_organization_id,
      :admin_code_prefix_for_fortresses, review.try(:created_at))

    review ? review.next_fortress_code(code_prefix) : "#{code_prefix}1".strip
  end
end
