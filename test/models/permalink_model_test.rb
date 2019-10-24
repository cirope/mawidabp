require 'test_helper'

class PermalinkModelTest < ActiveSupport::TestCase
  setup do
    @permalink_model = permalink_models :link_being_implemented_weakness
  end

  test 'blank attributes' do
    @permalink_model.permalink = nil
    @permalink_model.model = nil

    assert @permalink_model.invalid?
    assert_error @permalink_model, :permalink, :required
    assert_error @permalink_model, :model, :required
  end
end
