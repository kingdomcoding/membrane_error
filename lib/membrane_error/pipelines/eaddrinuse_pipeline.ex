defmodule MembraneError.Pipelines.GoodPipeline do
  use Membrane.Pipeline
  require Logger

  # Example ffmpeg command to start a stream:
  # ffmpeg -re -i ./sample.mp4 -c copy -f flv "rtmp://localhost:5001/super_account/super_key"
  #
  #
  # NOTE: This uses Membrane.Tee.PushOutput. To watch it fail, start a stream then turn off your wifi

  @super_secret_rtmp_url "rtmp://a.rtmp.youtube.com/live2/r14q-4gss-c3zj-m5ps-7ddm"

  

  def handle_new_client(client_ref, username, stream_key) do
    Logger.info("""
    New client connection attempt for username #{username} with stream_key #{stream_key}
    """)

    preview_video_hls_file = "./tmp/stream/preview_video/index.m3u8"

    Membrane.Pipeline.start_link(__MODULE__,
      %{
        client_ref: client_ref,
        preview_video_hls_dir: Path.dirname(preview_video_hls_file),
        preview_video_hls_manifest_name: Path.basename(preview_video_hls_file, ".m3u8"),
      }
    )

    {Membrane.RTMP.Source.ClientHandlerImpl, []}
  end

  @impl true
  def handle_init(_ctx, %{client_ref: client_ref, preview_video_hls_dir: preview_video_hls_dir, preview_video_hls_manifest_name: preview_video_hls_manifest_name}) do
    :ok = File.mkdir_p(preview_video_hls_dir)

    spec = [
      child(:rtmp_source, %Membrane.RTMP.SourceBin{client_ref: client_ref}),

      get_child(:rtmp_source)
      |> via_out(:audio)
      |> child(:audio_tee, Membrane.Tee.PushOutput),

      get_child(:rtmp_source)
      |> via_out(:video)
      |> child(:video_tee, Membrane.Tee.PushOutput),
    ]

    spec =
      [
        child(:preview_video_hls_sink_bin, %Membrane.HTTPAdaptiveStream.SinkBin{
          manifest_name: preview_video_hls_manifest_name,
          manifest_module: Membrane.HTTPAdaptiveStream.HLS,
          storage: %Membrane.HTTPAdaptiveStream.Storages.FileStorage{
            directory: preview_video_hls_dir
          },
          hls_mode: :separate_av,
          mp4_parameters_in_band?: true,
          target_window_duration: Membrane.Time.seconds(20)
        }),
        get_child(:audio_tee)
        |> child(:preview_video_hls_to_aac_transcoder, %Boombox.Transcoder{
          output_stream_format: Membrane.AAC
        })
        |> via_in(Pad.ref(:input, :audio),
          options: [encoding: :AAC, segment_duration: Membrane.Time.milliseconds(2000)]
        )
        |> get_child(:preview_video_hls_sink_bin),
        get_child(:video_tee)
        |> child(:preview_video_hls_to_h264_transcoder, %Boombox.Transcoder{
          output_stream_format: %Membrane.H264{alignment: :au, stream_structure: :avc3}
        })
        |> via_in(Pad.ref(:input, :video),
          options: [encoding: :H264, segment_duration: Membrane.Time.milliseconds(2000)]
        )
        |> get_child(:preview_video_hls_sink_bin)
        | spec
      ]


    spec = [
      child(:rtmp_sink_bin, %Membrane.RTMP.Sink{
        rtmp_url: @super_secret_rtmp_url,
        max_attempts: 10
      }),

      get_child(:audio_tee)
      |> via_in(Pad.ref(:audio, 0))
      |> get_child(:rtmp_sink_bin),

      get_child(:video_tee)
      |> via_in(Pad.ref(:video, 0))
      |> get_child(:rtmp_sink_bin)
      | spec
    ]

    {[spec: spec], %{}}
  end
end
