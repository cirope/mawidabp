class FileModelsController < ApplicationController
  before_action :auth

  def download
    base_regexp = /^#{allowed_paths}/

    if file_name =~ base_regexp && File.file?(file_name)
      set_file_download_headers
      response.headers['Last-Modified'] = File.mtime(file_name).httpdate

      send_file file_name, url_based_filename: true, type: mime_type
    else
      redirect_to controller: :welcome, action: :index
    end
  end

  private

    def file_name
      File.expand_path File.join(PRIVATE_PATH, params[:path] || '')
    end

    def mime_type
      mime = Mime::Type.lookup_by_extension File.extname(file_name)[1..-1]

      mime || 'application/octet-stream'
    end

    def allowed_paths
      paths = organization_paths.map { |p| Regexp.escape(p) }.join('|')

      paths << "|#{Regexp.escape flash[:allow_url]}" if flash[:allow_url]

      paths
    end

    def organization_paths
      paths = [organization_path(current_organization.id)]

      current_organization.group.organizations.each do |o|
        is_corporate = current_organization.corporate?
        has_organization_access = o.id != current_organization.id && @auth_user.organizations.include?(o)

        if is_corporate || has_organization_access
          paths << organization_path(o.id)
        end
      end

      paths
    end

    def organization_path organization_id
      "#{PRIVATE_PATH}#{File.join(('%08d' % organization_id).scan(/\d{4}/))}"
    end
end
