require 'test_helper'

class PollsHelperTest < ActionView::TestCase
  include FontAwesome::Sass::Rails::ViewHelpers

  setup do
    @answer = answers :answer_yes_no
  end

  test 'should return nil link to download answer attached' do
    assert_nil link_to_download_answer_attached(@answer)
  end

  test 'should return link to download answer attached' do
    @answer.attached = Rack::Test::UploadedFile.new TEST_IMAGE_FULL_PATH, 'png'

    options = {
      class: 'btn btn-outline-secondary',
      title: @answer.attached.identifier.titleize,
      data: { ignore_unsaved_data: true }
    }

    expected = link_to @answer.attached.url, options do
      icon 'fas', 'download'
    end

    assert_equal expected, link_to_download_answer_attached(@answer)
  end
end
