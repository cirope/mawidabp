module AutoCompleteFor::BusinessUnitType
  extend ActiveSupport::Concern

  def auto_complete_for_business_unit_type
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    conditions = [
      "#{::BusinessUnitType.quoted_table_name}.#{::BusinessUnitType.qcn('organization_id')} = :organization_id"
    ]
    parameters = { organization_id: current_organization.id }

    @tokens.reject!(&:blank?)

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{::BusinessUnitType.quoted_table_name}.#{::BusinessUnitType.qcn('name')}) LIKE :business_unit_type_data_#{i}"
      ].join(' OR ')

      parameters[:"business_unit_type_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @business_unit_types = ::BusinessUnitType.where(
      [conditions.map { |c| "(#{c})" }.join(' AND '), parameters]
    ).order(name: :asc).limit(10)

    respond_to do |format|
      format.json { render json: @business_unit_types }
    end
  end
end
