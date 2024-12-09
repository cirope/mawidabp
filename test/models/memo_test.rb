require 'test_helper'

class MemoTest < ActiveSupport::TestCase
  setup do
    @memo = memos :first_memo

    set_organization
  end

  test 'initialize with required by text' do
    assert @memo.required_by.blank?
    assert @memo.required_by_text.present?
    assert @memo.manual_required_by
  end

  test 'initialize with required by' do
    skip unless Memo::REQUIRED_BY_OPTIONS.present?

    @memo.manual_required_by = false
    @memo.required_by        = Memo::REQUIRED_BY_OPTIONS.first
    @memo.required_by_text   = nil

    @memo.save!
    @memo.reload

    assert @memo.required_by.present?
    assert @memo.required_by_text.blank?
    refute @memo.manual_required_by
  end

  test 'invalid because blank name' do
    @memo.name = ''

    refute @memo.valid?
    assert_error @memo, :name, :blank
  end

  test 'invalid because blank required by text' do
    @memo.required_by_text = ''

    refute @memo.valid?
    assert_error @memo, :required_by_text, :blank

    @memo.reload

    @memo.required_by_text   = ''
    @memo.manual_required_by = '1'

    refute @memo.valid?
    assert_error @memo, :required_by_text, :blank
  end

  test 'invalid because not included required by' do
    @memo.required_by        = ''
    @memo.manual_required_by = false

    refute @memo.valid?
    assert_error @memo, :required_by, :inclusion

    @memo.reload

    @memo.required_by        = ''
    @memo.manual_required_by = '0'

    refute @memo.valid?
    assert_error @memo, :required_by, :inclusion
  end

  test 'valid because required by included' do
    skip unless Memo::REQUIRED_BY_OPTIONS.present?

    @memo.manual_required_by = false
    @memo.required_by        = Memo::REQUIRED_BY_OPTIONS.first
    @memo.required_by_text   = nil

    assert @memo.valid?

    @memo.reload

    @memo.manual_required_by = '0'
    @memo.required_by        = Memo::REQUIRED_BY_OPTIONS.first
    @memo.required_by_text   = nil

    assert @memo.valid?
  end

  test 'invalid because delete all file model memos' do
    @memo.file_model_memos.each &:mark_for_destruction

    refute @memo.valid?
    assert_error @memo, :base, :file_model_memos_blank
  end

  test 'invalid because dont have file model memos' do
    file_model_memo = file_model_memos :file_model_first_memo

    file_model_memo.destroy!

    refute @memo.valid?
    assert_error @memo, :base, :file_model_memos_blank
  end

  test 'invalid because review have same plan item' do
    @memo.plan_item_id = (plan_items :current_plan_item_1).id

    refute @memo.valid?
    assert_error @memo, :plan_item_id, :used
  end

  test 'invalid because new record and another memo have same plan item' do
    memo              = Memo.new
    memo.plan_item_id = (plan_items :current_plan_item_6).id

    refute memo.valid?
    assert_error memo, :plan_item_id, :used
  end

  test 'invalid because another memo have same plan item' do
    memo = Memo.create!(
      name: 'Second memo',
      close_date: 15.days.from_now.to_date.to_s(:db),
      required_by: '',
      required_by_text: 'required by test',
      manual_required_by: true,
      period: periods(:current_period),
      organization: organizations(:cirope),
      plan_item: plan_items(:current_plan_item_4_without_business_unit),
      file_model_memos: [FileModelMemo.new(memo: memo, file_model: file_models(:text_file))])

    memo.plan_item = plan_items :current_plan_item_6

    refute memo.valid?
    assert_error memo, :plan_item_id, :used
  end

  test 'invalid because cant change fields' do
    @memo.update_attribute 'close_date', 1.days.ago.to_date.to_s(:db)

    @memo.name = 'test'

    refute @memo.valid?
    assert_error @memo, :base, :cant_change_fields
  end

  test 'invalid because cant change images' do
    @memo.update_attribute 'close_date', 1.days.ago.to_date.to_s(:db)

    @memo.file_model_memos.each &:mark_for_destruction

    refute @memo.valid?
    assert_error @memo, :base, :cant_change_fields

    @memo.reload

    @memo.association(:file_model_memos).add_to_target(FileModelMemo.new(memo: @memo, file_model: file_models(:text_file)))

    refute @memo.valid?
    assert_error @memo, :base, :cant_change_fields

    @memo.reload

    @memo.file_model_memos_attributes = [{ id: file_model_memos(:file_model_first_memo).id, file_model_attributes: { file: File.open(TEST_FILE_FULL_PATH) } }]

    refute @memo.valid?
    assert_error @memo, :base, :cant_change_fields
  end

  test 'should return false read only fields because new records' do
    memo = Memo.new

    refute memo.readonly_fields?
  end

  test 'should return false read only fields because close_date_was is less than today' do
    @memo.close_date = 15.days.ago.to_date.to_s(:db)

    refute @memo.readonly_fields?
  end

  test 'should return true read only fields because close_date_was is greater than today' do
    @memo.close_date = 15.days.ago.to_date.to_s(:db)

    @memo.save!

    @memo.close_date = 15.days.from_now.to_date.to_s(:db)

    assert @memo.readonly_fields?
  end

  test 'should return memos for organization' do
    Current.organization = organizations :cirope
    response             = Memo.list

    assert_equal 1, response.count
    assert_equal @memo.id, response.first.id
  end

  test 'should return blank memos for organization' do
    Current.organization = organizations :twitter
    response             = Memo.list

    assert response.blank?
  end
end
