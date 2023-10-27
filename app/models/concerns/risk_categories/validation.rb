module RiskCategories::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :name,
      pdf_encoding: true,
      length: { maximum: 255 },
      allow_nil: true, allow_blank: true

    validate :uniqueness_name
  end

  private

    def uniqueness_name
      if name.present?
        rcs = risk_registry.risk_categories.reject do |rc|
          rc == self || rc.marked_for_destruction?
        end

        if rcs.select { |rc| rc.name.strip =~ /^#{Regexp.quote(name.strip)}$/i }.any?
          errors.add :name, :taken
        end
      end
    end
end
