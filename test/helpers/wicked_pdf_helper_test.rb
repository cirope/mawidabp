require 'test_helper'

class WickedPdfHelperTest < ActionView::TestCase
  test 'Should return image in base64' do
    require 'base64'

    file      = File.open TEST_IMAGE_FULL_PATH
    extension = File.extname(TEST_IMAGE_FULL_PATH)[1..]
    base64    = Base64.encode64(file.read).gsub(/\s+/, '')

    file.close

    expected_result = "data:image/#{extension};base64,#{Rack::Utils.escape(base64)}"

    assert_equal expected_result, image_to_base_64(TEST_IMAGE_FULL_PATH)
  end

  test 'Should raise exception when path not exists' do
    assert_raise Errno::ENOENT do
      image_to_base_64('test.png')
    end
  end
end
