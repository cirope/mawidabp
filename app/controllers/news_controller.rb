class NewsController < ApplicationController
  include AutoCompleteFor::Tagging

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_news, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  def index
    build_search_conditions News

    @news = news.includes(:tags).where(@conditions).references(:tags).order(published_at: :desc).page params[:page]
  end

  def show
  end

  def new
    @news = news.new
  end

  def edit
  end

  def create
    @news = news.new news_params

    @news.save
    respond_with @news
  end

  def update
    update_resource @news, news_params
    respond_with @news
  end

  def destroy
    @news.destroy
    respond_with @news
  end

  private

    def set_news
      @news = news.find params[:id]
    end

    def news_params
      params.require(:news).permit :title, :description, :body, :published_at, :lock_version,
        taggings_attributes: [:id, :tag_id, :_destroy]
    end

    def news
      News.list
    end

    def load_privileges
      @action_privileges.update auto_complete_for_tagging: :read
    end
end
