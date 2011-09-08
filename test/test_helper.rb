ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Función para utilizar en las pruebas de los métodos que requieren
  # autenticación
  def perform_auth(user = users(:administrator_user),
      organization = organizations(:default_organization))
    @request.host = "#{organization.prefix}.localhost.i"
    temp_controller, @controller = @controller, UsersController.new
    password = user.is_encrypted? ? PLAIN_PASSWORDS[user.user] : user.password

    if session[:user_id]
      get :logout, :id => User.find(session[:user_id]).user
      assert_nil session[:user_id]
      temp_controller.instance_eval { @auth_user = nil }
      assert_redirected_to :controller => :users, :action => :login
    end

    post :create_session, {
      :user => { :user => user.user, :password => password }
    }, {}
    assert_redirected_to :controller => :welcome, :action => :index
    assert_not_nil session[:user_id]
    auth_user = User.find(session[:user_id])
    assert_not_nil auth_user
    assert_equal user.user, auth_user.user

    @controller = temp_controller
  end

  def get_test_parameter(parameter_name,
      organization = organizations(:default_organization))

    Parameter.find_parameter(organization.id, parameter_name)
  end

  def error_message_from_model(model, attribute, message, extra = {})
    ::ActiveModel::Errors.new(model).generate_message(attribute, message, extra)
  end

  def backup_file(file_name)
    if File.exists?(file_name)
      FileUtils.cp file_name, "#{TEMP_PATH}#{File.basename(file_name)}"
    end
  end
  
  def restore_file(file_name)
    if File.exists?("#{TEMP_PATH}#{File.basename(file_name)}")
      FileUtils.mv "#{TEMP_PATH}#{File.basename(file_name)}", file_name
    end
  end
end