require 'test_helper'

class BestPracticeTest < ActiveSupport::TestCase

  setup do
    @best_practice = best_practices :iso_27001

    set_organization
  end

  test 'create' do
    assert_difference 'BestPractice.count' do
      @best_practice = BestPractice.create(
        name: 'New name',
        description: 'New description'
      )
    end

    assert_equal organizations(:cirope).id,
      @best_practice.organization_id
  end

  test 'update' do
    assert @best_practice.update(name: 'Updated name'),
      @best_practice.errors.full_messages.join('; ')

    assert_equal 'Updated name', @best_practice.reload.name
  end

  test 'destroy' do
    assert_difference 'BestPractice.count', -1 do
      best_practices(:useless_best_practice).destroy
    end
  end

  test 'destroy with asociated control objectives' do
    assert_no_difference 'BestPractice.count' do
      @best_practice.destroy
    end

    assert_equal 1, @best_practice.errors.size
  end

  test 'validates blank atrtributes' do
    @best_practice = BestPractice.new name: ''
    @best_practice.group_id = nil
    @best_practice.organization_id = nil

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :blank
    assert_error @best_practice, :organization_id, :blank
    assert_error @best_practice, :group_id, :blank
  end

  test 'validates length of attributes' do
    @best_practice.name = 'abcdd' * 52

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :too_long, count: 255
  end

  test 'validates formated attributes' do
    @best_practice.organization_id = 'a'

    assert @best_practice.invalid?
    assert_error @best_practice, :organization_id, :not_a_number
  end

  test 'validates duplicated attributes' do
    @best_practice.name = best_practices(:bcra_A4609).name

    assert @best_practice.invalid?
    assert_error @best_practice, :name, :taken
  end

  test 'mark tags as shared when best practice gets shared' do
    assert @best_practice.control_objectives.any?

    @best_practice.control_objectives.all? do |co|
      assert co.tags.all? { |tag| !tag.shared }
    end

    @best_practice.update! shared: true

    @best_practice.control_objectives.reload.each do |co|
      assert co.tags.all?(&:shared)
    end
  end

  test 'mark tags as shared on best practice creation' do
    assert @best_practice.control_objectives.any?

    @best_practice.control_objectives.all? do |co|
      assert co.tags.all? { |tag| !tag.shared }
    end

    tag_ids = @best_practice.control_objectives.map do |co|
      co.tags.ids
    end.flatten.uniq

    assert tag_ids.any?

    assert_difference 'Tag.where(shared: true).count', tag_ids.size do
      attributes = @best_practice.attributes.merge(
        id: nil,
        name: 'New best practice',
        shared: true,
        process_controls_attributes: [
          {
            name: 'new process control',
            order: 1,
            control_objectives_attributes: [
              {
                name: 'new control objective 1 1',
                control_attributes: {
                  control: 'new control 1 1'
                },
                order: 1,
                taggings_attributes: tag_ids.map { |t_id| { tag_id: t_id } }
              }
            ]
          }
        ]
      )

      best_practice = BestPractice.create! attributes
    end

    @best_practice.control_objectives.reload.each do |co|
      assert co.tags.all?(&:shared)
    end
  end

  test 'to csv' do
    csv  = @best_practice.to_csv
    # TODO: change to liberal_parsing: true when 2.3 support is dropped
    rows = CSV.parse csv.sub("\uFEFF", ''), col_sep: ';', force_quotes: true

    assert_equal @best_practice.control_objectives.count + 1, rows.length
  end

  test 'hide obsolete best practices' do
    organization         = organizations :cirope
    Current.organization = organization # Since we use list below

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '1'

    @best_practice.update! obsolete: true

    assert_equal BestPractice.visible.count, BestPractice.count - 1

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '0'

    assert_equal BestPractice.visible.count, BestPractice.count

    organization.settings.find_by(name: 'hide_obsolete_best_practices').destroy

    if DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value] == '0'
      assert_equal BestPractice.visible.count, BestPractice.count
    else
      assert_equal BestPractice.visible.count, BestPractice.count - 1
    end
  ensure
    Current.organization = nil
  end
end
