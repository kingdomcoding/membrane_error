defmodule MembraneError.Repo do
  use Ecto.Repo,
    otp_app: :membrane_error,
    adapter: Ecto.Adapters.Postgres
end
