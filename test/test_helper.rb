ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/pride'

class ActiveSupport::TestCase
  set_fixture_class versions: PaperTrail::Version

  fixtures :all

  def set_organization organization = organizations(:default_organization)
    Organization.current_id = organization.id
  end

  def login user: users(:administrator_user), prefix: organizations(:default_organization).prefix
    @request.host         = "#{prefix}.lvh.me"
    session[:user_id]     = user.id
    session[:last_access] = Time.now

    user.logged_in! session[:last_access]
  end

  def get_test_parameter parameter_name, organization = organizations(:default_organization)
    Setting.find_by(name: parameter_name, organization_id: organization.id).value
  end

  def backup_file file_name
    if File.exists?(file_name)
      FileUtils.cp file_name, "#{TEMP_PATH}#{File.basename(file_name)}"
    end
  end

  def restore_file file_name
    if File.exists?("#{TEMP_PATH}#{File.basename(file_name)}")
      FileUtils.mv "#{TEMP_PATH}#{File.basename(file_name)}", file_name
    end
  end

  def assert_error model, attribute, type, options = {}
    assert model.errors[attribute].include?(
      model.errors.generate_message(attribute, type, options)
    )
  end
end
