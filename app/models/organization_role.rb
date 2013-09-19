class OrganizationRole < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id },
    :important => true
  }

  # Named scopes
  scope :for_group, ->(group_id) {
    includes(:organization).where(
      "#{Organization.table_name}.group_id" => group_id
    )
  }

  # Restricciones
  validates :organization_id, :role_id, :presence => true
  validates :user_id, :organization_id, :role_id,
    :numericality => {:only_integer => true}, :allow_nil => true,
    :allow_blank => true
  validates_each :role_id do |record, attr, value|
    organization_roles = record.user.try(:organization_roles) || []
    same_organization_roles = organization_roles.select do |o_r|
      o_r.organization_id == record.organization_id &&
        !o_r.marked_for_destruction?
    end

    same_organization_roles.each do |o_r|
      another_record = (!record.new_record? && o_r.id != record.id) ||
        (record.new_record? && o_r.object_id != record.object_id)

      # Control para evitar roles duplicados
      if another_record && o_r.role_id == value
        record.errors.add attr, :taken
      end
    end

    unless same_organization_roles.blank?
      # Control para evitar roles que sean mutuamente excluyentes
      not_audited = same_organization_roles.all? { |o_r| !o_r.role.audited? }
      all_audited = same_organization_roles.all? { |o_r| o_r.role.audited? }

      record.errors.add attr, :invalid unless not_audited ^ all_audited
    end
  end

  # Relaciones
  belongs_to :user, -> { readonly }
  belongs_to :organization, -> { readonly }
  belongs_to :role, -> { readonly }

  def to_s
    "#{self.role.name} (#{self.organization.name})"
  end
end
