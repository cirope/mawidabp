class Group < ActiveRecord::Base
  include Trimmer

  trimmed_fields :name

  has_paper_trail

  # Restricciones
  validates_presence_of :name
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false

  # Relaciones
  has_many :organizations, :dependent => :destroy

  accepts_nested_attributes_for :organizations, :allow_destroy => true
end