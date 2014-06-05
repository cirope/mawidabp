require 'test_helper'

class ErrorRecordTest < ActiveSupport::TestCase

  def setup
    set_organization

    @error_record = ErrorRecord.find(
      error_records(:administrator_user_failed_attempt).id)
  end

  test 'create' do
    assert_difference 'ErrorRecord.count' do
      @error_record = ErrorRecord.list.create(
        error: 1,
        data: 'Some data',
        user_id: users(:administrator_user).id
      )
    end
  end

  test 'update' do
    assert @error_record.update(data: 'New data'),
      @error_record.errors.full_messages.join('; ')
    assert_equal 'New data', @error_record.reload.data
  end

  test 'delete' do
    assert_difference 'ErrorRecord.count', -1 do
      @error_record.destroy
    end
  end

  test 'validates inclusion attributes' do
    @error_record.error = ErrorRecord::ERRORS.values.sort.last.next

    assert @error_record.invalid?
    assert_error @error_record, :error, :inclusion
  end
end
