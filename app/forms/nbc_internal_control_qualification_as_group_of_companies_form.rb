# frozen_string_literal: true

class NbcInternalControlQualificationAsGroupOfCompaniesForm < NbcAnnualReportForm
  property :business_unit_type_id
  property :previous_period_id

  validates :business_unit_type_id,
            :previous_period_id,
            presence: true

  def business_unit_type
    BusinessUnitType.find business_unit_type_id
  end

  def previous_period
    Period.find previous_period_id
  end

  private

    #HACER ALGUN TIPO DE VALIDACION PARA QUE NO SEA EL MISMO O QUE LA FECHA DE FIN SEA MENOR
end
