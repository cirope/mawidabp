module Reports::WeaknessesGraph
  extend ActiveSupport::Concern

  included do
    before_action :set_graph_weaknesses

    include AutoCompleteFor::BusinessUnit
    include AutoCompleteFor::ProcessControl
  end

  def weaknesses_graphs
    if @weaknesses && @weaknesses.empty?
      @info = t('.empty')
    end

    @weaknesses_data = @weaknesses && Weakness.weaknesses_for_graph(@weaknesses)
  end

  private

    def set_graph_weaknesses
      weaknesses = Weakness.finals(params[:final] == 'true')
      parameters = params[:weaknesses_graphs] || {}

      if parameters[:user_id].present?
        @weaknesses = weaknesses.for_user parameters[:user_id]
      elsif parameters[:business_unit_id].present?
        @weaknesses = weaknesses.for_business_unit parameters[:business_unit_id]
      elsif parameters[:process_control_id].present?
        @weaknesses = weaknesses.for_process_control parameters[:process_control_id]
      end
    end
end
