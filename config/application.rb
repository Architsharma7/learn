require_relative 'boot'

require 'rails/all'
require "view_component/engine"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Learn
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

  	config.generators do |g|
  	  g.orm :active_record, primary_key_type: :uuid
  	end

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    config.x.application_job.default_url_options = { host: "https://learnawesome.org" }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
