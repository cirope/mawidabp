module Users::Auditable
  extend ActiveSupport::Concern

  included do
    has_paper_trail(
      ignore: [:last_access, :logged_in, :updated_at, :lock_version],
      meta: {
        important: ->(user) { user.is_an_important_change },
        organization_id: ->(model) { Current.organization.id }
      }
    )
  end
end
