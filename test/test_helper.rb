require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'

Sidekiq::Testing.inline!

class ActiveSupport::TestCase
  set_fixture_class versions: PaperTrail::Version

  fixtures :all

  def set_organization organization = organizations(:cirope)
    Current.group        = organization.group
    Current.organization = organization
  end

  def login user: users(:administrator), prefix: organizations(:cirope).prefix
    set_host_for_organization(prefix)
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
    error = model.errors.generate_message attribute, type, options

    assert_includes model.errors[attribute], error
  end

  def set_host_for_organization(prefix)
    @request.host = [prefix, URL_HOST].join('.')
  end

  def perform_job_with_current_attributes(job)
    # Situación problematica. Al ejecutar `perform_now/deliver_now`
    # CurrentAttributes es reseteado por la forma de funcionar de Rails.
    # En Desarrollo/Produccion esto no es un problema ya que nada es `_now`
    # pero en modo test al usar helpers "inline" esto sucede.
    # Para solucionarlo encolamos los trabajos y los ejecutamos en un
    # "Contexto Controlado" gracias a `Current.set`

    job_class = job[:job]
    mailer, mail_method, delivery_method, *args = job[:args]

    new_args = args.map do |arg|
      if arg.kind_of?(Hash)
        if (gid = arg['_aj_globalid']).present?
          GlobalID::Locator.locate(gid)
        else
          arg.with_indifferent_access
        end
      else
        arg
      end
    end

    Current.set(Current.instance.attributes) do
      perform_enqueued_jobs do
        ancestors = job_class.ancestors

        if ancestors.include? ActiveJob::Base
          job_class.perform_now(job[:args])
        elsif ancestors.include? ActionMailer::Bas
          job_class.perform_now(mailer, mail_method, delivery_method, *new_args)
        end
      end
    end
  end
end
