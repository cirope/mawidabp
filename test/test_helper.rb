require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/pride'
require 'sidekiq/testing'

Sidekiq::Testing.inline!

class ActiveSupport::TestCase
  set_fixture_class versions: PaperTrail::Version

  fixtures :all

  def set_organization organization = organizations(:cirope)
    Group.current_id        = organization.group_id
    Organization.current_id = organization.id
  end

  def login user: users(:administrator_user), prefix: organizations(:cirope).prefix
    @request.host         = [prefix, ENV['APP_HOST']].join('.')
    session[:user_id]     = user.id
    session[:last_access] = Time.now

    user.logged_in! session[:last_access]
  end

  def get_test_parameter name, organization = organizations(:cirope)
    Setting.find_by(name: name, organization_id: organization.id).value
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
