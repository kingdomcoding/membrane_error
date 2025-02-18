defmodule MembraneErrorWeb.StreamController do
  use MembraneErrorWeb, :controller

  def show(conn, %{"file" => file}) do
    case File.read("./tmp/stream/preview_video/#{file}") do
      {:ok, file} ->
        send_resp(conn, 200, file)
      {:error, _error} ->
        send_resp(conn, 404, "HLS file not found")
    end
  end
end
