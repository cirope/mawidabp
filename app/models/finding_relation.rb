class FindingRelation < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  TYPES = {
    :duplicated => 0,
    :related => 1
  }

  # Restricciones
  validates_presence_of :finding_relation_type, :related_finding_id
  validates_inclusion_of :finding_relation_type, :in => TYPES.values,
    :allow_nil => true, :allow_blank => true
  validates_each :related_finding_id do |record, attr, value|
    repeated_relations = record.finding.finding_relations.select do |fr|
      fr.related_finding_id == value
    end

    record.errors.add attr, :taken if repeated_relations.size > 1
  end
  
  # Relaciones
  belongs_to :finding
  belongs_to :related_finding, :class_name => 'Finding'

  # Definición dinámica de todos los métodos "tipo?"
  TYPES.each do |type, value|
    define_method("#{type}?".to_sym) { self.finding_relation_type == value }
  end

  def finding_relation_type_text
    I18n.t("finding_relation.types.#{TYPES.invert[self.finding_relation_type]}")
  end
end