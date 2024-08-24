module WickedPdfHelper
  def image_to_base_64 path
    require 'base64'

    file      = File.open path
    extension = File.extname(path)[1..]
    base64    = Base64.encode64(file.read).gsub(/\s+/, '')

    file.close

    "data:image/#{extension};base64,#{Rack::Utils.escape(base64)}"
  end
end
