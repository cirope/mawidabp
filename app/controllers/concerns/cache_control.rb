module CacheControl
  extend ActiveSupport::Concern

  included do
    after_action :set_cache_control, unless: :downloading_file?
  end

  def set_file_download_headers
    @_file_headers = true
    response.headers['Cache-Control'] = 'private, no-store'
  end

  private

    def set_cache_control
      if @auth_user
        response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
      end
    end

    def downloading_file?
      @_file_headers
    end
end
