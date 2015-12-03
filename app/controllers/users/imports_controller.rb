class Users::ImportsController < ApplicationController
  before_action :auth, :check_privileges

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

    @deprecated_users = User.list.where(conditions.join(' AND '), parameters)
  rescue Net::LDAP::Error
    redirect_to new_users_import_url, alert: t('.connection')
  end

  private

    def import_params
      params.require(:import).permit :username, :password
    end
end
