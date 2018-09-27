require 'test_helper'

class AttachedReportJobTest < ActiveJob::TestCase
  test 'zip and email collection' do
    AttachedReportJob.perform_now(
      model_name:      'Finding',
      ids:             Finding.all.ids,
      filename:        'super_report.csv',
      method_name:     'to_csv',
      user_id:         users(:administrator).id,
      organization_id: organizations(:cirope).id
    )
    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    attachment = ActionMailer::Base.deliveries.last.attachments.first
    assert_equal 'super_report.zip', attachment.filename

    tmp_file = Tempfile.open do |temp|
      temp.binmode
      temp << attachment.read
      temp.path
    end

    csv_report = Zip::File.open(tmp_file, Zip::File::CREATE) do |zipfile|
      zipfile.read 'super_report.csv'
    end

    csv = CSV.parse csv_report, col_sep: ';', force_quotes: true, headers: true

    assert_equal csv.size, Finding.all.count
    FileUtils.rm_f tmp_file
  end
end
