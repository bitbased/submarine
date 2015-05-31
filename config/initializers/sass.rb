require 'sass/plugin'
#::Sass::Plugin.options[:load_paths] = Rails.application.config.assets[:paths].to_a
::Sass::Plugin.options[:load_paths] = Rails.application.config.sass[:load_paths].to_a
::Sass::Plugin.options[:cache] = false
#::Sass::Plugin.options[:load_paths] = Compass.configuration.sass_load_paths