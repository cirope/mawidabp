module FlashHelper
  def flash_message
    flash[:alert] || flash[:notice]
  end

  def show_flash_message?
    flash_message && %w(passwords sessions).exclude?(controller_name)
  end

  def flash_class
    flash[:alert] ? 'alert-danger' : 'alert-info'
  end
end
