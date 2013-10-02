class NotificationsController < ApplicationController
  before_action :auth, :check_privileges, :except => :confirm
  before_action :set_notification, only: [:show, :edit, :update]

  # * GET /notifications
  # * GET /notifications.xml
  def index
    @title = t 'notification.index_title'
    @notifications = Notification.where(:user_id => @auth_user.id).order(
      ['status ASC', 'created_at DESC']
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notifications }
    end
  end

  # * GET /notifications/1
  # * GET /notifications/1.xml
  def show
    @title = t 'notification.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification }
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
  # * PATCH /notifications/1.xml
  def update
    @title = t 'notification.edit_title'

    respond_to do |format|
      if @notification.update(notification_params)
        flash.notice = t 'notification.correctly_updated'
        format.html { redirect_to(notifications_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @notification.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'notification.stale_object_error'
    redirect_to :action => :edit
  end

  # * GET /notifications/confirm
  # * GET /notifications/confirm.xml
  def confirm
    @notification = Notification.where(
      :status => Notification::STATUS[:unconfirmed],
      :confirmation_hash => params[:id]
    ).first

    @auth_organization =
      @notification.try(:user).try(:organizations).try(:first)

    @notification.notify!(params[:reject].blank?) if @notification

    go_to = {:controller => :notifications, :action => :edit,
      :id => @notification.to_param}

    unless login_check
      message = t('notification.confirmed') if @notification.try(:confirmed?)
      message = t('notification.rejected') if @notification.try(:rejected?)
      session[:go_to] = go_to unless params[:reject].blank?

      redirect_to_login message
    else
      redirect_to params[:reject].blank? ? :back : go_to
    end
  rescue ActionController::RedirectBackError
    redirect_to notifications_url
  end

  private
    def set_notification
      @notification = Notification.where(
        :confirmation_hash => params[:id], :user_id => @auth_user.id
      ).first
    end

    def notification_params
      params.require(:notification).permit(:notes)
    end
end
