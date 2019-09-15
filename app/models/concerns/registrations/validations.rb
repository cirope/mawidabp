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

      org_name = organization.downcase

      if Group.where('LOWER(name) = :name', name: org_name).exists? ||
         Organization.where('LOWER(name) = :name', name: org_name).exists?

        self.errors.add :organization, :taken
      end
    end

    def organization_prefix_not_reserved
      return if errors[:organization].any?

      prefix = organization.parameterize

      if APP_ADMIN_PREFIXES.include?(prefix) || Organization.where(prefix: prefix).exists?
        self.errors.add :organization, :taken # ?
      end
    end

    def admin_email_uniqueness
      return if errors[:email].any?

      if Group.where('LOWER(admin_email) = :email', email: self.email.downcase).exists?
        self.errors.add :email, :taken
      end
    end
end
