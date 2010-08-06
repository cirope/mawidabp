require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  fixtures :users, :organizations

  def setup
    @controller.send(:reset_session)
    @controller.send(:session)[:user_id] = users(:administrator_user).id
    @controller.send(:session)[:organization_id] =
      organizations(:default_organization).id
    @controller.send(:session)[:last_access] = 30.seconds.ago
    @controller.send('response=', @response)
    @controller.send('request=', @request)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  test 'sucess login check function' do
    assert session[:user_id]
    assert session[:organization_id]

    User.find(users(:administrator_user).id).update_attribute(:logged_in, true)

    assert @controller.send(:login_check)
    assert @controller.instance_variable_defined?(:@auth_user)
    assert @controller.instance_variable_defined?(:@auth_organization)
  end

  test 'failed login check function' do
    assert session[:user_id]
    assert session[:organization_id]

    assert !@controller.send(:login_check)
  end

  test 'sucess auth function' do
    User.find(users(:administrator_user).id).update_attribute(:logged_in, true)

    assert @controller.send(:auth)
    assert @controller.instance_variable_defined?(:@action_privileges)
    assert @controller.instance_variable_defined?(:@auth_privileges)
  end

  test 'check correct access time function' do
    login_admin
    
    assert @controller.send(:check_access_time)
    assert_nil @controller.send(:session)[:go_to]
    assert_not_nil @controller.instance_variable_get(:@auth_user)
    assert_response :success
  end

  test 'check access time expired function' do
    login_admin
    @controller.send(:session)[:last_access] = 1.year.ago

    assert @controller.send(:check_access_time)
    assert_not_nil @controller.send(:session)[:go_to]
    assert_nil @controller.instance_variable_get(:@auth_user)
    assert_redirected_to login_users_url
    assert_equal I18n.t(:'message.session_time_expired'),
      @controller.send(:flash)[:alert]
  end

  test 'redirect to index function' do
    # TODO: intentar probar esto (de todas formas no es crucial para el
    # funcionamiento)
    #    @controller = UsersController.new
    #    @controller.send('response=', @response)
    #    @controller.send('request=', @request)
    #    @controller.send(:headers)
    #
    #    @controller.send(:redirect_to_index)
    #    assert_redirected_to :controller => :users, :action => :index
  end

  test 'redirect to login function' do
    login_admin

    @controller.send(:redirect_to_login)
    assert_redirected_to login_users_url
  end

  test 'restart session function' do
    login_admin
    @controller.send(:session)[:session_test] = 'test'
    @controller.send(:flash)[:flash_test] = 'test'
    assert_not_nil @controller.send(:session)[:session_test]
    assert_not_nil @controller.send(:flash)[:flash_test]
    @controller.send(:restart_session)
    assert_nil @controller.send(:session)[:session_test]
    assert_not_nil @controller.send(:flash)[:flash_test]
  end

  test 'check privileges function' do
    login_admin
    @controller.class.instance_variable_set(:@controller_name, 'users')
    @controller.send('action_name=', 'index')

    @controller.send(:check_privileges)
    assert_nil  @controller.send(:flash)[:notice]
    assert_response :success
  end

  test 'check group admin function' do
    login_admin
    @controller.class.instance_variable_set(:@controller_name, 'users')
    @controller.send('action_name=', 'index')

    @controller.send(:check_group_admin)
    assert_nil  @controller.send(:flash)[:notice]
    assert_response :success
  end

  test 'check no privileges function' do
    login_admin
    @controller.instance_variable_set(:@auth_privileges,
      Hash.new(Hash.new(false)))
    @controller.class.instance_variable_set(:@controller_name, 'users')
    @controller.send('action_name=', 'index')

    @controller.send(:check_privileges)
    assert_not_nil  @controller.send(:flash)[:alert]
    assert_redirected_to login_users_url
  end

  test 'make date range' do
    from_date = Date.today.at_beginning_of_month
    to_date = Date.today.at_end_of_month

    assert_equal [from_date, to_date], @controller.send(:make_date_range)

    # Fechas inválidas
    assert_equal [from_date, to_date], @controller.send(:make_date_range,
      {:from_date => 'wrong date', :to_date => 'another wrong date'})

    from_date = Date.parse '2011-10-09'
    to_date = Date.parse '2000-10-09'

    # Fechas válidas con el orden invertido
    assert_equal [to_date, from_date], @controller.send(:make_date_range,
      {:from_date => '2011-10-09', :to_date => '2000-10-09'})
  end

  test 'build search conditions' do
    search_string = []
    filters = {}
    default_conditions = {"#{Organization.table_name}.organization_id" => 1}
    @controller.send(:params)[:search] = {
      :query => 'query',
      :columns => ['name', 'user']
    }

    generated_search_string = @controller.send(:build_search_conditions, User,
      default_conditions)

    ['name', 'user'].each do |column|
      filter = "#{User.get_column_name(column)} "
      filter << User.get_column_operator(column)
      search_string << "#{filter} :#{column}_filter"
      filters["#{column}_filter".to_sym] = User.get_column_mask(column) %
        'query'
    end

    expected_search_string = User.prepare_search_conditions(default_conditions,
      ["(#{search_string.join(' OR ')})", filters])

    assert_equal expected_search_string, generated_search_string
  end

  private

  def login_admin
    User.find(users(:administrator_user).id).update_attribute(:logged_in, true)

    assert @controller.send(:auth)
  end
end