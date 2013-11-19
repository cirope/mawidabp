class HelpItem < ActiveRecord::Base
  include ActsAsTree

  acts_as_tree :order => 'order_number ASC'

  has_paper_trail meta: { organization_id: ->(obj) { Organization.current_id } }

  # Restricciones
  validates :name, :description, :order_number, :presence => true
  validates :order_number, :numericality => {:only_integer => true},
    :allow_nil => true, :allow_blank => true
  validates :name, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :help_content

  accepts_nested_attributes_for :children, :allow_destroy => true

  def complete_path
    path = [self.name]

    self.ancestors.each { |ancestor| path << ancestor.name }

    path.reverse.join APP_ENUM_SEPARATOR
  end

  def is_or_include?(id)
    self.id == id || self.children.any? { |child| child.is_or_include?(id) }
  end
end
