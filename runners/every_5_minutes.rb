Rails.logger.info "Starting every_5_minutes runner (version #{APP_REVISION[0,8]})"

EMail.fetch

Rails.logger.info "every_5_minutes runner finished (version #{APP_REVISION[0,8]})"
