class Fortress < Finding
  # Acceso a los atributos
  attr_reader :approval_errors

  # Named scopes
  scope :all_for_report, -> {
    where(
      :final => true
    )
  }

  # Restricciones
  validates_each :review_code do |record, attr, value|
    regex = /\A#{record.prefix}\d+\Z/

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
    work_paper.code_prefix = I18n.t('code_prefixes.work_papers_in_fortresses')
  end

  def last_work_paper_code(review = nil)
    code_prefix = I18n.t('code_prefixes.work_papers_in_fortresses')

    code_from_review = begin
      review ||= self.control_objective_item.reload.review
      review.last_fortress_work_paper_code(code_prefix)
    rescue
      "#{code_prefix} 0".strip
    end

    code_from_fortress = self.work_papers.reject(
      &:marked_for_destruction?).map(
      &:code).select { |c| c =~ /#{code_prefix}\s\d+/ }.sort.last

    [code_from_review, code_from_fortress].compact.max
  end

  def prefix
    I18n.t('code_prefixes.fortresses')
  end

  def next_code(review = nil)
    review ||= self.control_objective_item.reload.review
    review.next_fortress_code(self.prefix)
  rescue
    "#{self.prefix}1".strip
  end
end
