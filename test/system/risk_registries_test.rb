require "application_system_test_case"

class RiskRegistriesTest < ApplicationSystemTestCase
  setup do
    @risk_registry = risk_registries(:one)
  end

  test "visiting the index" do
    visit risk_registries_url
    assert_selector "h1", text: "Risk Registries"
  end

  test "creating a Risk registry" do
    visit risk_registries_url
    click_on "New Risk Registry"

    fill_in "Description", with: @risk_registry.description
    fill_in "Name", with: @risk_registry.name
    click_on "Create Risk registry"

    assert_text "Risk registry was successfully created"
    click_on "Back"
  end

  test "updating a Risk registry" do
    visit risk_registries_url
    click_on "Edit", match: :first

    fill_in "Description", with: @risk_registry.description
    fill_in "Name", with: @risk_registry.name
    click_on "Update Risk registry"

    assert_text "Risk registry was successfully updated"
    click_on "Back"
  end

  test "destroying a Risk registry" do
    visit risk_registries_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Risk registry was successfully destroyed"
  end
end
