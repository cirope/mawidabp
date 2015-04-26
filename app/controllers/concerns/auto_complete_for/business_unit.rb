module AutoCompleteFor::BusinessUnit
  extend ActiveSupport::Concern

  def auto_complete_for_business_unit
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    conditions = [
      "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('organization_id')} = :organization_id"
    ]
    parameters = { organization_id: current_organization.id }

    @tokens.reject!(&:blank?)

    if params[:business_unit_type_id].to_i > 0
      conditions << "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('id')} = :but_id"
      parameters[:but_id] = params[:business_unit_type_id].to_i
    end

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('name')}) LIKE :business_unit_data_#{i}"
      ].join(' OR ')

      parameters[:"business_unit_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @business_units = BusinessUnit.includes(:business_unit_type).where(
      [conditions.map { |c| "(#{c})" }.join(' AND '), parameters]
    ).order(
      [
        "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('name')} ASC",
        "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC"
      ]
    ).references(:business_unit_type).limit(10)

    respond_to do |format|
      format.json { render json: @business_units }
    end
  end
end
