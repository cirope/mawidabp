class TagsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  def index
    @tags = scope.
      search(query: params[:q]).
      limit(request.xhr? && 10).
      reorder(:obsolete, :name).
      page params[:page]
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

    if @tag.save
      redirect_with_notice @tag, url: [@tag, kind: @tag.kind]
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def update
    if @tag.update tag_params
      redirect_with_notice @tag, url: [@tag, kind: @tag.kind]
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy
    redirect_with_notice @tag, url: [@tag, kind: @tag.kind]
  end

  private

    def set_tag
      @tag = scope.find params[:id]
    end

    def tag_params
      params.require(:tag).permit :name, :style, :shared, :obsolete, :icon,
        :lock_version, children_attributes: [:id, :name, :_destroy],
        options: {}
    end

    def scope
      Tag.list.roots.where kind: params[:kind]
    end
end
