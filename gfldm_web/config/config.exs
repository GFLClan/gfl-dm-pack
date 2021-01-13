# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :gfldm_web,
  ecto_repos: [GfldmWeb.Repo]

# Configures the endpoint
config :gfldm_web, GfldmWebWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OnYyfZxYOO6XeNuWIS15BhZn4wVGJlA0oTWP+JK75Dgg42aFLKxkX3xODHbpVKlP",
  render_errors: [view: GfldmWebWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GfldmWeb.PubSub,
  live_view: [signing_salt: "zqWFt492"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
