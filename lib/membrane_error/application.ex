defmodule MembraneError.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MembraneErrorWeb.Telemetry,
      MembraneError.Repo,
      {DNSCluster, query: Application.get_env(:membrane_error, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MembraneError.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MembraneError.Finch},
      # Start a worker by calling: MembraneError.Worker.start_link(arg)
      # {MembraneError.Worker, arg},
      # Start to serve requests, typically the last entry
      MembraneErrorWeb.Endpoint,
      rtmp_server()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MembraneError.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp rtmp_server() do
    {Membrane.RTMPServer, [
      port: 5001,
      use_ssl?: false,
      handle_new_client: &MembraneError.Pipelines.GoodPipeline.handle_new_client/3
    ]}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MembraneErrorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
