module WeaknessTemplates::Validations
  extend ActiveSupport::Concern

  included do
    attr_accessor :allow_duplication

    before_validation :clean_array_attributes

    validates :title, :description, presence: true, pdf_encoding: true
    validates :title, length: { maximum: 255 }, allow_blank: true
    validates :title, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }, unless: :allow_duplication?
  end

  def allow_duplication?
    allow_duplication == '1' || allow_duplication == true
  end

  private

    def clean_array_attributes
      self.impact = Array(impact).reject &:blank?
      self.operational_risk = Array(operational_risk).reject &:blank?
      self.internal_control_components =
        Array(internal_control_components).reject &:blank?
    end
end
