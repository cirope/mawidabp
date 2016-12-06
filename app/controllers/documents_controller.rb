class DocumentsController < ApplicationController
  include AutoCompleteFor::Tagging

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_tag, only: [:index]
  before_action :set_document, only: [:show, :edit, :update, :destroy, :download]
  before_action :set_title, except: [:destroy]

  def index
    build_search_conditions Document

    if @tag
      @documents = documents.includes(:tags).where(@conditions).references(:tags).order(:name).page params[:page]
    else
      @document_tags   = Tagging.grouped_with_document_count
      @documents_count = @document_tags.values.sum
    end

    respond_with @documents
  end

  def show
  end

  def new
    @document = documents.new
  end

  def edit
  end

  def create
    @document = documents.new document_params

    @document.save
    respond_with @document
  end

  def update
    update_resource @document, document_params
    respond_with @document
  end

  def destroy
    @document.destroy
    respond_with @document
  end

  def download
    url = flash[:allow_url] = @document.file_model&.file&.url

    redirect_to url || root_url
  end

  private

    def set_document
      @document = documents.find params[:id]
    end

    def set_tag
      @tag = Tag.list.find params[:tag_id] if params[:tag_id]
    end

    def document_params
      params.require(:document).permit :name, :description, :shared, :lock_version,
        file_model_attributes: [:id, :file, :file_cache, :_destroy],
        taggings_attributes:   [:id, :tag_id, :_destroy]
    end

    def documents
      @tag ? @tag.documents.list : Document.list
    end

    def load_privileges
      @action_privileges.update(
        download: :read,
        auto_complete_for_tagging: :read
      )
    end
end
