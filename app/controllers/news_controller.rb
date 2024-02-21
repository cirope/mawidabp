class NewsController < ApplicationController
  include AutoCompleteFor::Tagging

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_news, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy, :auto_complete_for_tagging]

  def index
    @news = news.includes(:tags).search(
      **search_params
    ).references(:tags).order(published_at: :desc).page params[:page]
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

    if @news.save
      redirect_with_notice @news
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def update
    if @news.update news_params
      redirect_with_notice @news
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    @news.destroy
    redirect_with_notice @news
  end

  private

    def set_news
      @news = news.find params[:id]
    end

    def news_params
      params.require(:news).permit :title, :description, :body, :published_at,
        :shared, :lock_version,
        taggings_attributes:     [:id, :tag_id, :_destroy],
        image_models_attributes: [:id, :image, :image_cache, :_destroy]
    end

    def news
      News.list
    end

    def load_privileges
      @action_privileges.update auto_complete_for_tagging: :read
    end
end
