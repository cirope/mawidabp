class Questionnaire < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  # Constantes
  POLLABLE_TYPES = [
    'ConclusionReview'
  ]

  # Validaciones
  validates :name, :organization_id, :presence => true
  validates_uniqueness_of :name, :allow_nil => true, :allow_blank => true
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :organization
  has_many :polls, :dependent => :destroy
  has_many :questions, :dependent => :destroy,
    :order => "#{Question.table_name}.sort_order ASC"
  # Named scopes
  scope :by_pollable_type, lambda { |type|
    where(:pollable_type => type)
  }
  scope :list, lambda {
    where(:organization_id => GlobalModelConfig.current_organization_id)
  }
  scope :by_organization, lambda {
    |org_id, id| where('id = :id AND organization_id = :org_id', :org_id => org_id, :id => id)
  }

  accepts_nested_attributes_for :questions, :allow_destroy => true
end
