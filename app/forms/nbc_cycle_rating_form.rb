# frozen_string_literal: true

class NbcCycleRatingForm < NbcAnnualReportForm
  property :business_unit_type_id
  property :previous_period_id

  validates :previous_period_id,
            :business_unit_type_id,
            presence: true
  validate :previous_period_must_be_before_period

  def business_unit_type
    BusinessUnitType.find business_unit_type_id
  end

  def previous_period
    Period.list.find_by_id previous_period_id
  end

  private

    def previous_period_must_be_before_period
      if self.previous_period && self.period && self.previous_period.start >= self.period.start
        errors.add :previous_period_id, :must_be_before_period
      end
    end
end
