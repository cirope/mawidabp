class NotificationsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  before_action :set_notification, only: [:show, :edit, :update, :confirm]

  # * GET /notifications
  def index
    @title = t 'notification.index_title'
    @notifications = Notification.where(:user_id => @auth_user.id).order(
      :status => :asc, :created_at => :desc
    ).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # * GET /notifications/1
  def show
    @title = t 'notification.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Recupera los datos para modificar una notificación de mejora
  #
  # * GET /notifications/1/edit
  def edit
    @title = t 'notification.edit_title'
    redirect_to notifications_url unless @notification
  end

  # Actualiza el contenido de una notificación siempre que cumpla con las
  #  validaciones.
  #
  # * PATCH /notifications/1
  def update
    @title = t 'notification.edit_title'

    respond_to do |format|
      if @notification.update(notification_params)
        flash.notice = t 'notification.correctly_updated'
        format.html { redirect_to(notifications_url) }
      else
        format.html { render :action => :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'notification.stale_object_error'
    redirect_to :action => :edit
  end

  # * GET /notifications/1/confirm
  def confirm
    @notification.notify! params[:reject].blank? if @notification.unconfirmed?

    redirect_to @notification, :notice => t('notification.confirmed')
  end

  private

    def set_notification
      @notification = Notification.where(
        confirmation_hash: params[:id], user_id: @auth_user.id
      ).take!
    end

    def notification_params
      params.require(:notification).permit :notes, :lock_version
    end

    def load_privileges
      @action_privileges.update(
        confirm: :modify
      )
    end
end
