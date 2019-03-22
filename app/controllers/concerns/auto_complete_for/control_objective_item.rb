module AutoCompleteFor::ControlObjectiveItem
  extend ActiveSupport::Concern

  def auto_complete_for_control_objective_item
    @tokens = params[:q][0..100].split(SEARCH_AND_REGEXP).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Period.quoted_table_name}.#{Period.qcn('organization_id')} = :organization_id",
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NULL",
      "#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('review_id')} = :review_id"
    ]
    parameters = {
      organization_id: current_organization.id,
      review_id: params[:review_id].to_i
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('control_objective_text')}) LIKE :control_objective_item_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_item_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @control_objective_items = ControlObjectiveItem.includes(
      review: [:period, :conclusion_final_review]
    ).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      Arel.sql "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC"
    ).references(
      :periods, :conclusion_reviews, :control_objective_items
    ).limit(10)

    respond_to do |format|
      format.json { render json: @control_objective_items }
    end
  end
end
