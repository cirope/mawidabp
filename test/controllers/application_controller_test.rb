require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  fixtures :users, :organizations

  setup do
    @request.host = "#{organizations(:cirope).prefix}.test.host.co"

    @controller.send(:reset_session)
    @controller.send(:session)[:user_id] = users(:administrator).id
    @controller.send(:session)[:last_access] = 30.seconds.ago
    @controller.send('response=', @response)
    @controller.send('request=', @request)

    @controller.class.instance_variable_set(:@controller_name, nil)
    @controller.class.instance_variable_set(:@controller_path, nil)

    set_organization
  end

  test 'sucess login check function' do
    assert session[:user_id]

    User.find(users(:administrator).id).update_attribute(:logged_in, true)

    assert @controller.send(:login_check)
    assert @controller.instance_variable_defined?(:@auth_user)
    assert @controller.instance_variable_defined?(:@current_organization)
  end

  test 'failed login check function' do
    assert session[:user_id]

    User.find(users(:administrator).id).update_attribute(:enable, false)
    refute @controller.send(:login_check)
  end

  test 'sucess auth function' do
    User.find(users(:administrator).id).update_attribute(:logged_in, true)

    assert @controller.send(:auth)
    assert @controller.instance_variable_defined?(:@action_privileges)
    assert @controller.instance_variable_defined?(:@auth_privileges)
  end

  test 'not sucess auth function' do
    User.find(users(:administrator).id).update_attribute(:logged_in, true)
    User.find(users(:administrator).id).update_attribute(:enable, false)

    assert @controller.send(:auth)
    refute @controller.instance_variable_defined?(:@action_privileges)
    refute @controller.instance_variable_defined?(:@auth_privileges)
    assert_redirected_to login_url
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
    assert_redirected_to login_url
    assert_equal I18n.t('message.session_time_expired'),
      @controller.send(:flash)[:alert]
  end

  test 'redirect to login function' do
    login_admin

    @controller.send(:redirect_to_login)
    assert_redirected_to login_url
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

    @controller.class.instance_variable_set(:@controller_path, 'users')
    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security_users' => {
          read: true
        }
      }
    )
    @controller.send('action_name=', 'index')
    @controller.send(:check_privileges)

    assert_nil @controller.send(:flash)[:notice]
    assert_response :success
  end

  test 'check no privileges function' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')
    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security_users' => {
          read: false
        }
      }
    )
    @controller.send('action_name=', 'index')
    @controller.send(:check_privileges)

    assert_not_nil @controller.send(:flash)[:alert]
    assert_redirected_to login_url
  end

  test 'check privileges function in dropdownmenu when children have privileges' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          read: true
        },
        'administration_security_users' => {
          read: true
        }
      }
    )
    @controller.send('action_name=', 'index')
    @controller.send(:check_privileges)

    assert_nil @controller.send(:flash)[:notice]
    assert_redirected_to users_url
  end

  test 'check no privileges function in dropdownmenu when children not have privileges' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          read: true
        },
        'administration_security_users' => {
          read: false
        }
      }
    )
    @controller.send('action_name=', 'index')
    @controller.send(:check_privileges)

    assert_not_nil @controller.send(:flash)[:alert]
    assert_redirected_to login_url
  end

  test 'check no privileges function in dropdownmenu' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          read: false
        },
        'administration_security_users' => {
          read: true
        }
      }
    )
    @controller.send('action_name=', 'index')
    @controller.send(:check_privileges)

    assert_not_nil @controller.send(:flash)[:alert]
    assert_redirected_to login_url
  end

  test 'check can perform function' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')
    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security_users' => {
          modify: true
        }
      }
    )

    assert @controller.send(:can_perform?, :edit, :modify)
  end

  test 'check cannot perform function' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')
    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security_users' => {
          approval: false
        }
      }
    )

    refute @controller.send(:can_perform?, :edit, :approval)
  end

  test 'check can perform function in dropdownmenu when children have privileges' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          modify: true
        },
        'administration_security_users' => {
          modify: true
        }
      }
    )

    assert @controller.send(:can_perform?, :edit, :modify)
  end

  test 'check cannot perform function in dropdownmenu when children not have privileges' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          modify: true
        },
        'administration_security_users' => {
          modify: false
        }
      }
    )

    refute @controller.send(:can_perform?, :edit, :modify)
  end

  test 'check cannot perform function in dropdownmenu' do
    login_admin

    @controller.class.instance_variable_set(:@controller_path, 'users')

    @controller.params[:drop_down_menu] = true

    @controller.instance_variable_set(
      :@auth_privileges, {
        'administration_security' => {
          modify: false
        },
        'administration_security_users' => {
          modify: true
        }
      }
    )

    refute @controller.send(:can_perform?, :edit, :modify)
  end

  test 'check group admin' do
    login_admin

    @controller.send(:check_group_admin)

    assert_nil @controller.send(:flash)[:alert]
    assert_response :success
  end

  test 'check not group admin' do
    login_admin

    administrator             = User.find(users(:administrator).id)
    administrator.group_admin = false

    administrator.save!

    assert @controller.send :auth

    @controller.send(:check_group_admin)

    assert_not_nil @controller.send(:flash)[:alert]
    assert_redirected_to login_url
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

    generated_range = @controller.send(:make_date_range, {
        :from_date => '2011-10-09', :to_date => '2000-10-09'
      }).map { |d| d.to_s(:db) }

    # Fechas válidas con el orden invertido
    assert_equal [to_date.to_s(:db), from_date.to_s(:db)], generated_range
  end

  test 'extract operator' do
    result = @controller.send(:extract_operator, '> test of extraction')

    assert_equal ['test of extraction', '>'], result

    result = @controller.send(:extract_operator, 'z> test of extraction')

    assert_equal 'z> test of extraction', result
  end

  test 'build search conditions' do
    search_string = []
    filters = {}
    default_conditions = {"#{Organization.quoted_table_name}.organization_id" => 1}
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

  test 'set file download headers' do
    assert_nil response.headers['Cache-Control']

    @controller.send :set_file_download_headers

    assert_equal 'private, no-store', response.headers['Cache-Control']
  end

  test 'redirect to blocked license' do
    skip unless ENABLE_PUBLIC_REGISTRATION

    login_admin

    @controller.send :redirect_to_license_blocked

    assert_redirected_to license_blocked_url
  end

  private

    def login_admin
      users(:administrator).update_attribute :logged_in, true

      assert @controller.send :auth
    end
end
