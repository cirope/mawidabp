class FileModelsController < ApplicationController
  before_filter :auth
  
  def download
    redirect = true

    file_name = File.expand_path(File.join(PRIVATE_PATH, params[:path] || ''))
    base_regexp = %r(^#{Regexp.escape(PRIVATE_PATH)})

    if file_name =~ base_regexp && File.file?(file_name)
      response.headers['Cache-Control'] = 'private'
      extname = File.extname(file_name)[1..-1]
      mime_type = Mime::Type.lookup_by_extension(extname)

      send_file file_name, :x_sendfile => (Rails.env == 'production'),
        :url_based_filename => true, :type => mime_type
      redirect = false
    end

    redirect_to :controller => :welcome, :action => :index if redirect
  end
end