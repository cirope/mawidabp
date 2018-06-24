class Privilege < ApplicationRecord
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Current.organization_id }
  }

  after_validation :mark_implicit_privileges

  # Restricciones
  validates :module, :presence => true
  validates :module, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :module, :inclusion => {:in => APP_MODULES}, :allow_nil => true,
    :allow_blank => true
  validates_each :module do |record, attr, value|
    ## Permitido el por el tipo de rol
    allowed_modules = record.role.allowed_modules if record.role

    if !value.blank? && !(allowed_modules || []).include?(value)
      record.errors.add attr, :invalid
    end

    # Único dentro del rol
    is_duplicated = record.role && record.role.privileges.any? do |p|
      another_record = (!record.new_record? && p.id != record.id) ||
        (record.new_record? && p.object_id != record.object_id)

      record.module? && p.module? &&
        p.module.downcase == record.module.downcase && another_record &&
        !record.marked_for_destruction?
    end

    record.errors.add attr, :taken if is_duplicated
  end

  # Relaciones
  belongs_to :role

  def mark_implicit_privileges
    self.read ||= (self.modify ||= self.erase) || self.approval
  end

  def to_s
    privilege_string = I18n.t(self.module, :scope => :actioncontroller)

    privilege_array = [:approval, :erase, :modify, :read].map do |p|
      "#{Privilege.human_attribute_name(p)}: " +
        I18n.t(self.send(p) ? 'label.yes' : 'label.no')
    end

    "#{privilege_string} (#{privilege_array.join(', ')})"
  end
end
