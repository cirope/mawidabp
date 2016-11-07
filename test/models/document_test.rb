require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @document               = documents :audit_manual
    Group.current_id        = @document.group_id
    Organization.current_id = @document.organization_id
  end

  teardown do
    Group.current_id        = nil
    Organization.current_id = nil
  end

  test 'blank attributes' do
    @document.name = ''
    @document.file_model = nil
    @document.group = nil
    @document.organization = nil

    assert @document.invalid?
    assert_error @document, :name, :blank
    assert_error @document, :file_model, :blank
    assert_error @document, :group, :blank
    assert_error @document, :organization, :blank
  end

  test 'unique attributes' do
    document = @document.dup

    assert document.invalid?
    assert_error document, :name, :taken
  end

  test 'attributes length' do
    @document.name = 'abcde' * 52

    assert @document.invalid?
    assert_error @document, :name, :too_long, count: 255
  end

  test 'file model gets organization id set' do
    assert_equal @document.organization_id, @document.file_model.organization_id
  end

  test 'mark tags as shared when document gets shared' do
    assert @document.tags.all? { |tag| !tag.shared }

    @document.update! shared: true

    assert @document.reload.tags.all?(&:shared)
  end

  test 'mark tags as shared on document creation' do
    assert @document.tags.all? { |tag| !tag.shared }

    assert_difference 'Tag.where(shared: true).count', @document.tags.not_shared.count do
      attributes = @document.attributes.merge(
        id: nil,
        name: 'New document',
        shared: true,
        taggings_attributes: @document.taggings.map { |t| t.attributes.merge(id: nil) }
      )

      document = Document.create! attributes
    end

    assert @document.reload.tags.all?(&:shared)
  end

  test 'search' do
    documents = Document.search query: @document.name

    assert documents.any?
    assert documents.all? { |s| s.name =~ /#{@document.name}/ }
  end
end
