module AutoCompleteFor::Tagging
  extend ActiveSupport::Concern

  def auto_complete_for_tagging
    @tags = Tag.list.search(query: params[:q]).where(kind: params[:kind]).limit 10

    respond_to do |format|
      format.json { render json: @tags }
    end
  end
end
