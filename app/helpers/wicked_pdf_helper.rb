module WickedPdfHelper
  def active_storage_to_base64_image
    require "base64"
    file = File.open(Organization.first.image_model.image.thumb.path)
    base64 = Base64.encode64(file.read).gsub(/\s+/, '')
    file.close
    "data:image/png;base64,#{Rack::Utils.escape(base64)}"
  end
end
