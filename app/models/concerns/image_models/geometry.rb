module ImageModels::Geometry
  extend ActiveSupport::Concern

  def image_size style_name = nil
    image_geometry = image_geometry style_name

    "#{image_geometry[:width]}x#{image_geometry[:height]}"
  end

  def image_geometry version = nil
    dimensions = {}
    path       = get_version(version).path

    if path.present? && File.exist?(path)
      MiniMagick::Image.open(path)[:dimensions].tap do |dimension|
        dimensions.merge! width: dimension.first, height: dimension.last
      end
    end

    dimensions
  end

  private

    def get_version version = nil
      version ? image.send(version) : image
    end
end
