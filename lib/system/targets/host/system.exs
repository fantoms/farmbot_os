defmodule Module.concat([Farmbot,System,"host"]) do
  @moduledoc false
  @behaviour Farmbot.System
  def reboot, do: :ok
  def power_off, do: :ok
  def factory_reset do
    Farmbot.System.FS.transaction fn() ->
      File.rm_rf "/tmp/config.json"
      File.rm_rf "/tmp/secret"
      File.rm_rf "/tmp/farmware"
      File.rm_rf "/tmp/secret.backup"
      System.halt(0)
    end
  end
end
