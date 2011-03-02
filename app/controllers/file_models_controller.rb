class FileModelsController < ApplicationController
  before_filter :auth
  
  def download
    redirect = true

    file_name = File.expand_path(File.join(PRIVATE_PATH, params[:path] || ''))
    organization = Organization.find(GlobalModelConfig.current_organization_id)
    organization_paths = ["#{PRIVATE_PATH}#{File.join(('%08d' %
      (GlobalModelConfig.current_organization_id || 0)).scan(/\d{4}/))}"]
    organization.group.organizations.each do |o|
      if o.id != organization.id && @auth_user.organizations.include?(o)
        organization_paths <<
          "#{PRIVATE_PATH}#{File.join(('%08d' % (o.id || 0)).scan(/\d{4}/))}"
      end
    end
    allowed_paths = organization_paths.map { |p| Regexp.escape(p) }.join('|')

    base_regexp = /^(#{allowed_paths})/

    if file_name =~ base_regexp && File.file?(file_name)
      response.headers['Cache-Control'] = 'private'
      extname = File.extname(file_name)[1..-1]
      mime_type = Mime::Type.lookup_by_extension(extname)

      send_file file_name, :url_based_filename => true,
        :type => (mime_type || 'application/octet-stream')
      redirect = false
    end

    redirect_to :controller => :welcome, :action => :index if redirect
  end
end