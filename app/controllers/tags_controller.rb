class TagsController < ApplicationController
  respond_to :html, :json

  before_action :auth, :check_privileges
  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  def index
    @tags = scope.search(query: params[:q]).limit(request.xhr? && 10).order(:name).page params[:page]

    respond_with @tags
  end

  def show
  end

  def new
    @tag = scope.new
  end

  def edit
  end

  def create
    @tag = scope.new tag_params

    @tag.save
    respond_with @tag, location: [@tag, kind: @tag.kind]
  end

  def update
    update_resource @tag, tag_params
    respond_with @tag, location: [@tag, kind: @tag.kind]
  end

  def destroy
    @tag.destroy
    respond_with @tag, location: [@tag, kind: @tag.kind]
  end

  private

    def set_tag
      @tag = scope.find params[:id]
    end

    def tag_params
      params.require(:tag).permit :name, :style, :lock_version
    end

    def scope
      Tag.list.where(kind: params[:kind])
    end
end
