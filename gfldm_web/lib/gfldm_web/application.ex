defmodule GfldmWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      GfldmWeb.Repo,
      # Start the Telemetry supervisor
      GfldmWebWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: GfldmWeb.PubSub},
      # Start the Endpoint (http/https)
      GfldmWebWeb.Endpoint
      # Start a worker by calling: GfldmWeb.Worker.start_link(arg)
      # {GfldmWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GfldmWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GfldmWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
