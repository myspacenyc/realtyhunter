 Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  # config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present? #deprecated in 5.1
  config.public_file_server.enabled = true
  # config.static_cache_control = "public, max-age=31536000" #deprecated in 5.1
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=31536000' }
  # serve from CDN
  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV['CLOUDFRONT_ENDPOINT']

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :warn

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  config.cache_store = :redis_store, {expires_in: 1.day, race_condition_ttl: 10} #, "redis://localhost:6379/0/cache"
  config.action_controller.perform_caching = true

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  host = 'myspace-realty-monster.herokuapp.com'
  config.action_mailer.default_url_options = { host: host }

  # use mandril
  # ActionMailer::Base.smtp_settings = {
  #   :port =>           '587',
  #   :address =>        'smtp.mandrillapp.com',
  #   :user_name =>      ENV['MANDRILL_USERNAME'],
  #   :password =>       ENV['MANDRILL_APIKEY'],
  #   :domain =>         'heroku.com',
  #   :authentication => :plain
  # }
  #ActionMailer::Base.delivery_method = :smtp
  # use postmark
  # config.action_mailer.delivery_method = :postmark
  # config.action_mailer.postmark_settings = {api_token: ENV['POSTMARK_API_KEY']} 

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.paperclip_defaults = {
    storage: :s3,
    url: ':s3_alias_url',
    s3_host_alias: ENV['CLOUDFRONT_ENDPOINT'],
    path: '/:class/:attachment/:id_partition/:style/:filename',
    s3_protocol: 'https',
    s3_credentials: {
      bucket: ENV['S3_AVATAR_BUCKET'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      s3_region: ENV["AWS_REGION"],
    },
    # s3_headers: {
    #   'Cache-Control': 'max-age=315576000',
    #   'Expires': 10.years.from_now.httpdate
    # }
    compression: {
      png: '-o 7 -quiet',
      jpeg: '-copy none -optimize'
    }
  }
  config.action_controller.perform_caching = true
  config.action_mailer.delivery_method = :smtp #:test
  config.action_mailer.perform_deliveries = true
  # config.action_mailer.smtp_settings = {
  # :address              => "smtp.postmarkapp.com",
  # :port                 => 587,
  # :domain               => 'myspacenyc.com',
  # :user_name            => '4ffc058c-7aa0-4dd7-a686-e252c09465cb',
  # :password             => '4ffc058c-7aa0-4dd7-a686-e252c09465cb',
  # :authentication       => 'plain',
  # :enable_starttls_auto => true  }

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.smtp_settings = {
      :address              => 'smtp.gmail.com',
      :port                 => '465',
      :domain               => 'gmail.com',
      :user_name            => 'myspacenyc@myspacenyc.com',
      :password             => '@#$@#$msnyc@#$@#$msnyc@#$@#$',
      :authentication       => :login,
      :ssl                  => true,
      :openssl_verify_mode  => 'none' #Use this because ssl is activated but we have no certificate installed. So clients need to confirm to use the untrusted url.
  }
end
