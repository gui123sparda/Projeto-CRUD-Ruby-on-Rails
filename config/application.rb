require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module ProjetoRubyTreinamento
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "America/Fortaleza"
    config.active_record.schema_format = :sql
    config.active_record.dump_schemas = :all
    config.paths["db/migrate"] = "db/migrations"

    config.autoload_lib(ignore: %w[assets tasks])
  end
end
