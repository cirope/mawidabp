# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'javascripts', 'wicked_pdf')
# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w(
  bootstrap.min.js
  popper.js
  jquery3.min.js
  jquery_ujs.js
  jquery-ui/effects/effect-highlight.js
  jquery-ui/i18n/datepicker-es.js
  jquery-ui/widgets/autocomplete.js
  jquery-ui/widgets/datepicker.js
  jquery-ui/widgets/dialog.js
  jquery-ui/widgets/sortable.js
  jquery-ui/widgets/autocomplete.js
  wicked_pdf/number_pages.js
  wicked_pdf/bic_pdf/set_background_image.js
)
