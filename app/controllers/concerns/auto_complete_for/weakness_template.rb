module AutoCompleteFor::WeaknessTemplate
  extend ActiveSupport::Concern

  def auto_complete_for_weakness_template
    @tokens = params[:q][0..100].split(SEARCH_AND_REGEXP).uniq
    @tokens.reject! &:blank?
    conditions = []
    parameters = {}

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{WeaknessTemplate.quoted_table_name}.#{WeaknessTemplate.qcn('title')}) LIKE :weakness_template_data_#{i}"
      ].join(' OR ')

      parameters[:"weakness_template_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @weakness_templates = WeaknessTemplate.list.where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order("#{WeaknessTemplate.quoted_table_name}.#{WeaknessTemplate.qcn('title')} ASC").limit(10)

    respond_to do |format|
      format.json { render json: @weakness_templates }
    end
  end
end
