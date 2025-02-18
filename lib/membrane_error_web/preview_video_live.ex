defmodule MembraneErrorWeb.PreviewVideoLive do
  use MembraneErrorWeb, :live_view

  def render(assigns) do
    ~H"""
    <video id="player" class="w-full rounded-lg" phx-hook="Player" data-source={"/stream/preview_video"} controls></video>
    """
  end
end
