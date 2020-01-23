class Users::ImportsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges, :set_title

  def new
  end

  def create
    ldap_config = current_organization.ldap_config
    @imports = ldap_config.import import_params[:username], import_params[:password]
    imported_user_ids = @imports.map { |i| i[:user].id }.compact
    conditions = []
    parameters = {}

    imported_user_ids.each_slice(1000).with_index do |user_ids, i|
      conditions << "#{User.quoted_table_name}.#{User.qcn('id')} NOT IN (:ids_#{i})"

      parameters[:"ids_#{i}"] = user_ids
    end

    @deprecated_users = User.list.not_hidden.where(conditions.join(' AND '), parameters)
  rescue Net::LDAP::Error
    redirect_to new_users_import_url, alert: t('.connection')
  end

  private

    def import_params
      params.require(:import).permit :username, :password
    end

    def load_privileges
      setting            = current_organization.settings.find_by name: 'hide_import_from_ldap'
      hide               = (setting ? setting.value : DEFAULT_SETTINGS[:hide_import_from_ldap][:value]) != '0'
      required_privilege = if hide
                             :approval
                           else
                             :read
                           end

      @action_privileges.update new:    required_privilege,
                                create: required_privilege
    end
end
