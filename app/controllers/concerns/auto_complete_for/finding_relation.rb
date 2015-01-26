module AutoCompleteFor::FindingRelation
  extend ActiveSupport::Concern

  def auto_complete_for_finding_relation
    @tokens = params[:q][0..100].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      ("#{Finding.table_name}.id <> :finding_id" unless params[:finding_id].blank?),
      "#{Finding.table_name}.final = :boolean_false",
      "#{Period.table_name}.organization_id = :organization_id",
      [
        "#{ConclusionReview.table_name}.review_id IS NOT NULL",
        ("#{Review.table_name}.id = :review_id" unless params[:review_id].blank?)
      ].compact.join(' OR ')
    ].compact
    parameters = {
      boolean_false: false,
      finding_id: params[:finding_id],
      organization_id: current_organization.id,
      review_id: params[:review_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.table_name}.review_code) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Finding.table_name}.title) LIKE :finding_relation_data_#{i}",
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Review.table_name}.identification) LIKE :finding_relation_data_#{i}",
      ].join(' OR ')

      parameters[:"finding_relation_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @findings = Finding.includes(
      control_objective_item: { review: [:period, :conclusion_final_review] }
    ).where(conditions.map {|c| "(#{c})"}.join(' AND '), parameters).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).references(:control_objective_items, :reviews, :periods).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end
end
