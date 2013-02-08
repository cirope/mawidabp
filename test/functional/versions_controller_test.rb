# -*- coding: utf-8 -*-
require 'test_helper'

# Pruebas para el controlador de versiones
class VersionsControllerTest < ActionController::TestCase
  fixtures :versions

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => versions(:important_version).to_param}
    public_actions = []
    private_actions = [
      [:get, :show, id_param],
      [:get, :security_changes_report]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'show version' do
    perform_auth
    get :show, :id => versions(:important_version).to_param
    assert_response :success
    assert_not_nil assigns(:version)
    assert_select '#error_body', false
    assert_select 'table.summary_table'
    assert_template 'versions/show'
  end

  test 'security changes report' do
    perform_auth
    get :security_changes_report
    assert_response :success
    assert_not_nil assigns(:versions)
    assert_select '#error_body', false
    assert_template 'versions/security_changes_report'
  end

  test 'download security changes report' do
    perform_auth
    from_date = Date.today.at_beginning_of_month
    to_date = Date.today.at_end_of_month

    assert_nothing_raised(Exception) do
      get :security_changes_report, :download => 1,
        :range => {:from_date => from_date, :to_date => to_date}
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('version.pdf_list_name',
        :from_date => from_date.to_formatted_s(:db),
        :to_date => to_date.to_formatted_s(:db)), Version.table_name)
  end
end
