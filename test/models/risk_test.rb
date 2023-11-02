require 'test_helper'

class RiskTest < ActiveSupport::TestCase
  setup do
    @risk = risks :risk
  end

  test 'create' do
    assert_difference ['Risk.count', 'RiskControlObjective.count'] do
      Risk.create(
        name: 'New name',
        identifier: 'New identifier',
        likelihood: Risk::LIKELIHOODS[:minor],
        impact: Risk::IMPACTS[:rare],
        cause: 'New cause',
        effect: 'New effect',
        user: users(:administrator),
        risk_category: @risk.risk_category,
        risk_control_objectives_attributes: [
          control_objective_id: control_objectives(:management_dependency).id
        ]
      )
    end
  end

  test 'update' do
    assert @risk.update(name: 'Updated name'), @risk.errors.full_messages.join('; ')
    @risk.reload
    assert_equal 'Updated name', @risk.name
  end

  test 'destroy' do
    assert_difference 'Risk.count', -1 do
      @risk.destroy
    end
  end

  test 'blank attributes' do
    @risk.identifier = ''
    @risk.name = ''
    @risk.likelihood = ''
    @risk.impact = ''

    @risk.risk_control_objectives.destroy_all

    assert @risk.invalid?
    assert_error @risk, :identifier, :blank
    assert_error @risk, :name, :blank
    assert_error @risk, :likelihood, :blank
    assert_error @risk, :impact, :blank
    assert_error @risk, :risk_control_objectives, :blank
  end

  test 'attribute length' do
    @risk.name = 'abcde' * 52
    @risk.identifier = 'abcde' * 52

    assert @risk.invalid?
    assert_error @risk, :name, :too_long, count: 255
    assert_error @risk, :identifier, :too_long, count: 255
  end

  test 'included attributes' do
    @risk.likelihood = -1
    @risk.impact = -1

    assert @risk.invalid?
    assert_error @risk, :likelihood, :inclusion
    assert_error @risk, :impact, :inclusion
  end

  test 'unique attributes' do
    risk = @risk.dup

    assert risk.invalid?
    assert_error risk, :name, :taken
    assert_error risk, :identifier, :taken
  end
end
