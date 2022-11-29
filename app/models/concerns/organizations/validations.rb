module Organizations::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :prefix, :logo_style, pdf_encoding: true, presence: true,
      length: { maximum: 255 }
    validates :description, pdf_encoding: true
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :logo_style, inclusion: {
      in: %w(default success info warning danger)
    }
    validates :saml_provider, inclusion: { in: %w(azure) }, allow_nil: true, allow_blank: true
    validates :prefix,
      format: { with: /\A[A-Za-z0-9][A-Za-z0-9\-]+\z/ },
      uniqueness: { case_sensitive: false },
      exclusion: { in: APP_ADMIN_PREFIXES }

    validate :images_extension
  end

  private

    def images_extension
      %i[image co_brand_image].each do |attribute|
        if send(attribute).attached? && %w[image/jpg image/jpeg image/gif image/png].exclude?(send(attribute).content_type)
          errors.add attribute, :extension_whitelist_error
        end
      end
    end
end
