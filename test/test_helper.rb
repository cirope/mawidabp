require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'sidekiq/testing'

Sidekiq::Testing.inline!

Net::LDAP::Connection.send :remove_const, 'DefaultConnectTimeout'
Net::LDAP::Connection::DefaultConnectTimeout = 1

class ActiveSupport::TestCase
  set_fixture_class versions: PaperTrail::Version
  parallelize(workers: 1)

  fixtures :all

  setup do
    create_carrierwave_dir
    change_dir_to_upload_files
  end

  teardown do
    clear_current_attributes

    try :clear_enqueued_jobs
    try :clear_performed_jobs

    FileUtils.rm_rf(Dir[PRIVATE_PATH])
  end

  def create_carrierwave_dir
    FileUtils.mkdir_p PRIVATE_PATH if !Dir.exist?(PRIVATE_PATH)
  end

  def change_dir_to_upload_files
    if defined?(CarrierWave)
      CarrierWave::Uploader::Base.descendants.each do |klass|
        next if klass.anonymous?
        klass.class_eval do
          def store_dir
            id = ('%08d' % model.id).scan(/\d{4}/).join('/')

            organization_id = (
              '%08d' % (model.organization_id || Current.organization&.id || 0)
            ).scan(/\d{4}/).join('/')

            "#{PRIVATE_PATH}#{organization_id}/#{model.class.to_s.underscore.pluralize}/#{id}"
          end
        end
      end
    end
  end

  def set_organization organization = organizations(:cirope)
    Current.group        = organization.group
    Current.organization = organization
    prefix               = organization.prefix

    if SHOW_CONCLUSION_ALTERNATIVE_PDF.respond_to?(:[])
      Current.conclusion_pdf_format = SHOW_CONCLUSION_ALTERNATIVE_PDF[prefix]
    end

    if USE_GLOBAL_WEAKNESS_REVIEW_CODE.include? prefix
      Current.global_weakness_code = true
    end

    Current.conclusion_pdf_format ||= 'default'
  end

  def clear_current_attributes
    Current.attributes.keys.each do |attribute|
      Current.send "#{attribute}=", nil
    end
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
    if File.exist?(file_name)
      FileUtils.cp file_name, "#{TEMP_PATH}#{File.basename(file_name)}"
    end
  end

  def restore_file file_name
    if File.exist?("#{TEMP_PATH}#{File.basename(file_name)}")
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

    new_args = args.first['args'].map do |arg|
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
        job_class.perform_now(mailer, mail_method, delivery_method, args: new_args)
      end
    end
  end

  def ldap_port
    ENV['GH_ACTIONS'] ? 3389 : 389
  end
end
