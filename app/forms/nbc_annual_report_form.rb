# frozen_string_literal: true

class NbcAnnualReportForm < Reform::Form
  property :period_id
  property :date
  property :cc
  property :name
  property :objective
  property :conclusion
  property :introduction_and_scope

  validates :period_id,
            :date,
            :cc,
            :name,
            :objective,
            :conclusion,
            :introduction_and_scope,
            presence: true

  def date=(value)
    super value.present? ? Date.parse(value) : nil
  end

  def self.human_attribute_name(attribute_key_name, options = {})
    I18n.t("activemodel.attributes.nbc_annual_report_form.#{attribute_key_name}")
  end

  def period
    Period.find period_id
  end
end
