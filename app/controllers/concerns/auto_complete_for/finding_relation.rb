module AutoCompleteFor::FindingRelation
  extend ActiveSupport::Concern

  def auto_complete_for_finding_relation
    @tokens = params[:q][0..100].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      ("#{Finding.quoted_table_name}.#{Finding.qcn('id')} <> :finding_id" unless params[:finding_id].blank?),
      "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
      "#{Period.quoted_table_name}.#{Period.qcn('organization_id')} = :organization_id",
      [
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        ("#{Review.quoted_table_name}.#{Review.qcn('id')} = :review_id" unless params[:review_id].blank?)
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
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('review_code')}) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('title')}) LIKE :finding_relation_data_#{i}",
        "LOWER(#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('control_objective_text')}) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')}) LIKE :finding_relation_data_#{i}",
      ].join(' OR ')

      parameters[:"finding_relation_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @findings = Finding.includes(
      control_objective_item: { review: [:period, :conclusion_final_review] }
    ).where(conditions.map {|c| "(#{c})"}.join(' AND '), parameters).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:control_objective_items, :reviews, :periods).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end
end
