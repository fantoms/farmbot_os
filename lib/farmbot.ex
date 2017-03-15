defmodule Farmbot do
  @moduledoc """
    Supervises the individual modules that make up the Farmbot Application.
  """
  require Logger
  use Supervisor
  alias Farmbot.Sync.Database
  alias Farmbot.System.Supervisor, as: FBSYS

  @spec init(map) :: [{:ok, pid}]
  def init(%{target: target,
             compat_version: compat_version,
             version: version,
             commit: commit})
  do
    children = [
      # system specifics
      supervisor(FBSYS, [target: target], restart: :permanent),
      # auth services
      worker(Farmbot.Auth, [], restart: :permanent),
      # web app
      supervisor(Farmbot.Configurator, [], restart: :permanent),
      # Generic counter.
      worker(Counter, [], restart: :permanent),
      # The worker for diffing db entries.
      worker(Farmbot.Sync.Supervisor, [], restart: :permanent),
      # Handles tracking of various parts of the bots state.
      supervisor(Farmbot.BotState.Supervisor,
        [%{target: target,
           compat_version: compat_version,
           version: version,
           commit: commit}], restart: :permanent),

      # Handles FarmEvents
      supervisor(FarmEvent.Supervisor, [], restart: :permanent),

      # Handles the passing of messages from one part of the system to another.
      supervisor(Farmbot.Transport.Supervisor, [], restart: :permanent),

      # Handles external scripts and what not
      supervisor(Farmware.Supervisor, [], restart: :permanent),

      # handles communications between bot and arduino
      supervisor(Farmbot.Serial.Supervisor, [], restart: :permanent),
      worker(Farmbot.ImageWatcher, [], restart: :permanent)
    ]
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  @doc """
    Entry Point to Farmbot
  """
  @spec start(atom, [any]) :: {:ok, pid}
  def start(type, args)
  def start(_, [args]) do
    Logger.info ">> init!"
    Amnesia.start
    Database.create! Keyword.put([], :memory, [node()])
    Database.wait(15_000)
    Supervisor.start_link(__MODULE__, args, name: Farmbot.Supervisor)
  end
end
