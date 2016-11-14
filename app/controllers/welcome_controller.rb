class WelcomeController < ApplicationController
  before_action :auth

  def index
    @title = t 'welcome.index_title'

    if @auth_user.audited?
      template = 'audited'
    else
      @document_tags   = Tagging.grouped_with_document_count
      @documents_count = @document_tags.values.sum
      template         = 'auditor'
    end

    render template: "welcome/#{template}_index"
  end
end
