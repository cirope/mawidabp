require 'test_helper'

# Pruebas para el controlador de buenas prácticas
class FileModelsControllerTest < ActionController::TestCase
  fixtures :organizations, :users

  def setup
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
    file_name = "#{TEMP_PATH}temp_test.txt"

    File.open(file_name, 'w') { |f| f << 'some test text' }

    @file_model = FileModel.create(:file => File.new(file_name))
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [
      [:get, :download, {:path => @file_model.file.url(:original, false).gsub(/^\/private/, "")}]
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

  test 'download file' do
    perform_auth
    get :download,
      {:path => @file_model.file.url(:original, false).gsub(/^\/private/, "")}
    assert_response :success
    assert_equal 'some test text', @response.body
  end

  test 'download unauthorized file' do
    perform_auth(users(:administrator_second_user),
      organizations(:second_organization))
    get :download,
      {:path => @file_model.file.url(:original, false).gsub(/^\/private/, "")}
    assert_redirected_to :controller => :welcome, :action => :index
  end
end