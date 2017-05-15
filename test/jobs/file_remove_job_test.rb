require 'test_helper'

class FileRemoveJobTest < ActiveJob::TestCase
  test 'remove' do
    path = Rails.root.join('test', "#{SecureRandom.uuid}.txt")

    FileUtils.touch path

    assert path.exist?

    FileRemoveJob.perform_now path

    assert !path.exist?
  end
end
