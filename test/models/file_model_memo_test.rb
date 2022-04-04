require 'test_helper'

class FileModelsMemoTest < ActiveSupport::TestCase
  setup do
    @file_model_memo = file_model_memos :file_model_first_memo
  end

  test 'blank attributes' do
    @file_model_memo.file_model_id = ''
    @file_model_memo.memo_id       = ''

    assert @file_model_memo.invalid?
    assert_error @file_model_memo, :file_model, :required
    assert_error @file_model_memo, :memo, :required
  end

  test 'unique attributes' do
    file_model_memo = @file_model_memo.dup

    assert file_model_memo.invalid?
    assert_error file_model_memo, :file_model_id, :taken
  end
end
