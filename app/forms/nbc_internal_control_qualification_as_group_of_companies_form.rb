# frozen_string_literal: true

class NbcInternalControlQualificationAsGroupOfCompaniesForm < NbcAnnualReportForm
  property :business_unit_type_id
  property :previous_period_id

  validates :business_unit_type_id,
            :previous_period_id,
            presence: true
  validate :periods_not_equal

  def business_unit_type
    BusinessUnitType.list.find business_unit_type_id
  end

  def previous_period
    Period.list.find previous_period_id
  end

  private

    def periods_not_equal
      if period_id == previous_period_id
        errors.add :period_id, :must_be_different
        errors.add :previous_period_id, :must_be_different
      end
    end
end
