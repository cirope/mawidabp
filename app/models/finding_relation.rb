class FindingRelation < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates :description, :related_finding_id, :presence => true
  validates :description, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates_each :related_finding_id do |record, attr, value|
    repeated_relations = record.finding.finding_relations.select do |fr|
      fr.related_finding_id == value
    end

    record.errors.add attr, :taken if repeated_relations.size > 1
  end
  
  # Relaciones
  belongs_to :finding
  belongs_to :related_finding, :class_name => 'Finding'
end