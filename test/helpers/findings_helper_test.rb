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
end
