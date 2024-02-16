module FlashResponders
  extend ActiveSupport::Concern

  def redirect_with_notice object, options = {}
		url = options.delete(:url) || object

    notice = {
      notice: flash.notice ||
        t(
          '.notice', resource_name: object.model_name.human, scope: [:flash]
        )
    }

    redirect_to url, notice.merge(options)
  end
end
