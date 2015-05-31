source 'https://rubygems.org'

ruby '2.1.2'

gem 'rails', '4.0'

group :development, :test do
  gem 'sqlite3'
  gem 'quiet_assets'
end

group :production do
  gem 'thin' # Heroku's web server
end

gem 'pg'

gem "haml"
gem 'compass-rails'
gem 'sass-rails'
gem 'bourbon'
gem 'neat'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'therubyracer'
  gem 'coffee-rails'

  gem 'haml_coffee_assets'
  gem 'execjs'

  gem 'uglifier'

  gem 'jquery-rails'
  gem 'jquery-ui-rails'

  gem 'jquery-fileupload-rails'
end

gem "backbone-on-rails"
#gem 'underscore-rails'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby'
gem 'cancan'

# Use unicorn as the app server
gem 'unicorn'

gem 'protected_attributes'

gem 'simple_form'
#gem 'paranoia', '~> 2.0'

gem 'redcarpet'
gem 'will_paginate'

gem 'aws-s3'
# gem 'wicked_pdf'
gem 'rmagick'
gem 'rails_12factor'

gem 'harvested'#, :git => 'git://github.com/zmoazeni/harvested.git', ref: "1fdb8aa90652d16653d0c8f04307dad5c0d0f107"

gem 'httparty'
gem 'hashie'
gem 'json'