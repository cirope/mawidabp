module Registrations::Validations
  extend ActiveSupport::Concern

  included do
    validates :organization, pdf_encoding: true, presence: true

    validate :organization_uniqueness, if: :organization
    validate :organization_prefix_not_reserved, if: :organization
    validate :admin_email_uniqueness, if: :email
  end

  private

    def organization_uniqueness
      return if errors[:organization].any?

      name = organization.downcase

      if Group.where('LOWER(name) = :name', name: name).exists? ||
         Organization.where('LOWER(name) = :name', name: name).exists?

        errors.add :organization, :taken
      end
    end

    def organization_prefix_not_reserved
      return if errors[:organization].any?

      prefix = organization.parameterize

      if APP_ADMIN_PREFIXES.include?(prefix) || Organization.where(prefix: prefix).exists?
        errors.add :organization, :taken
      end
    end

    def admin_email_uniqueness
      return if errors[:email].any?

      if Group.where('LOWER(admin_email) = :email', email: self.email.downcase).exists?
        errors.add :email, :taken
      end
    end
end
