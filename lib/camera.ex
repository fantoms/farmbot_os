defmodule Farmbot.Camera do
  @moduledoc """
    Test module for taking photos with the rpi camera.
  """

  # @params ["-o", "/tmp/image.jpg", "-e", "jpg", "-t", "1", "-w","1024", "-h", "1024"]
  # @command "raspistill"

  def params(path, extra_opts) do
    ~w"#{path}
    -d /dev/video0 -r 1280x720
    --no-banner --gmt
    --set sharpness=15
    --set gamma=10 --set contrast=75
    " ++ extra_opts
  end
  @command "fswebcam"
  # "fswebcam --save /tmp/image/image.jpg -d /dev/video0 -r 1280x720 --no-banner --gmt --skip 25 --set sharpness=15 --set gamma=10 --set contrast=75"
  require Logger

  def capture(path \\ nil, options \\ [])
  def capture(path, options) do
    command = System.find_executable(@command)
    path = path || out_path()
    port = Port.open({:spawn_executable, command},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout, args: params(path, options)])
    handle_port(port)
    File.read!(path)
  end

  defp handle_port(port) do
    receive do
      {^port, {:data, stuff}} ->
        IO.puts stuff
        handle_port(port)
      {^port, {:exit_status, _}} -> :ok
      _ -> handle_port(port)
    after 10_000 -> Logger.error "[CAMERA] UHHHHHH"
    end
  end

  defp out_path, do: "/tmp/images/#{Timex.now |> DateTime.to_unix(:milliseconds)}.jpg"

end
