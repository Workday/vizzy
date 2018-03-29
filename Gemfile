source 'https://rubygems.org'

ruby '2.3.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.7'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5.1.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'bootswatch-rails'
gem 'bootstrap-sass', '~> 3.3.5'
gem 'devise-bootstrap-views'
gem 'sprockets-rails', require: 'sprockets/railtie'

gem 'io-like'
# Use Gretel for breadcrumbs
gem 'gretel'

# Issue monitoring and bug finder
gem 'bugsnag', '~> 6.6.3'

gem 'rails_12factor'

gem 'concurrent-ruby', '~> 1.0.2'

# Use for uploading multipart images
gem 'multipart-post'

gem 'json'

# Use commontator for comments
gem 'commontator', '~> 5.1.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 1.0.0', group: :doc

# Paperclip for attachments
gem 'paperclip'
# Imagemagick for perceptual diffs
gem 'rmagick'

gem 'simple_token_authentication', '~> 1.15.1'

# Devise for auth/accounts
gem 'devise'

# LDAP for AD auth
gem 'net-ldap'

# PG for postgresql
gem 'pg'

# Use for translations
gem 'i18n', '0.7.0'

# Ability for models have a tree structure (hierarchy)
gem 'ancestry'

gem 'minitest-rails'
gem 'minitest-reporters', '~> 1.1.14'

# Schedule cron tasks
gem 'whenever', require: false

group :development, :test, :ci_test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'capybara'
  gem 'chromedriver-helper'
  gem 'factory_bot_rails'
  gem 'minitest-rails-capybara'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  # Mock requests for tests
  gem 'webmock'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.0.5'
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'better_errors'
  gem 'rails_real_favicon'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
