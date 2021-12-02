require 'test_helper'

class FindingsHelperTest < ActionView::TestCase
  test 'Should extension enabled when it never was being implementation' do
    finding = findings :incomplete_weakness

    assert extension_enabled?(finding)
  end

  test 'Should extension enabled when it is in the being implementation and has extension' do
    finding = findings :being_implemented_weakness

    finding.versions.each do |v|
      if v.object['state'] == Finding::STATUS[:being_implemented]
        v.object['extension'] = true
        v.save
      end
    end

    finding.extension = true

    assert extension_enabled?(finding)
  end

  test 'Should extension enabled when it is a new record' do
    finding = Finding.new

    assert extension_enabled?(finding)
  end

  test 'Should not extension enabled when have version in being implemented and extension in false' do
    finding = findings :being_implemented_weakness

    refute extension_enabled?(finding)
  end

  test 'Show attachment creation date when have file_model' do
    work_paper_with_file     = work_papers :image_work_paper
    file_model_creation_date = work_paper_with_file.file_model.created_at.strftime('%d/%m/%Y')

    assert_equal file_model_created_at(work_papers :image_work_paper), file_model_creation_date
  end

  test 'Dont show attachment creation date when not have file_model' do
    finding    = findings :being_implemented_weakness
    work_paper = finding.work_papers.first

    assert_equal file_model_created_at(work_paper), '-'
  end

  test 'Should first version in being implementation when is a new record' do
    finding = Finding.new

    assert first_version_in_being_implementation?(finding)
  end

  test 'Should first version in being implementation when it never was being implementation' do
    finding = findings :incomplete_weakness

    assert first_version_in_being_implementation?(finding)
  end

  test 'Should not first version in being implementation when have version in being implemented and extension in false' do
    finding = findings :being_implemented_weakness

    refute first_version_in_being_implementation?(finding)
  end

  test 'Data for submit' do
    skip unless USE_SCOPE_CYCLE

    finding       = findings :being_implemented_weakness
    expected_hash = {
                      data: {
                        confirm_message: I18n.t('findings.weakness.confirm_first_version_being_implemented_withou_extension',
                                                {
                                                  state: I18n.t('findings.state.being_implemented'),
                                                  extension: Finding.human_attribute_name(:extension)
                                                }),
                        checkbox_target: '#finding_extension',
                        target_value_checkbox: false,
                        state_target: Finding::STATUS[:being_implemented],
                        input_with_state: '#finding_state',
                        condition_to_receive_confirm: first_version_in_being_implementation?(finding) }
                    }

    assert_equal expected_hash, data_for_submit(finding)
  end
end
