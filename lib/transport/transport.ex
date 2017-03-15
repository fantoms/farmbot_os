alias Farmbot.BotState.Monitor
alias Farmbot.BotState.Monitor.State, as: MonState
defmodule Farmbot.Transport do
  @moduledoc """
    Serializes Farmbot's state to be send out to any subscribed transports.
  """
  use GenStage
  require Logger
  use Counter, __MODULE__
  # The max number of state updates before we force one
  @max_inactive_count 100

  defmodule Serialized do
    @moduledoc """
      Serialized Bot State
    """
    defstruct [:mcu_params,
               :location,
               :pins,
               :configuration,
               :informational_settings,
               :process_info,
               :user_env]

    @type t :: %__MODULE__{
      mcu_params: map,
      location: [integer,...],
      pins: map,
      configuration: map,
      informational_settings: map,
      process_info: map,
      user_env: map}
  end

  def start_link, do: GenStage.start_link(__MODULE__, [], name: __MODULE__)

  def init([]), do: {:producer_consumer, %Serialized{}, subscribe_to: [Monitor]}

  def handle_call(:get_state, _from, state), do: {:reply, state, [], state}

  def handle_call(:force_state_push, _from, state) do
    reset_count()
    GenStage.async_notify(__MODULE__, {:status, state})
    {:reply, state, [], state}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      Logger.info "#{__MODULE__} got event: #{inspect event} "
    end
    {:noreply, events, state}
  end

  defp translate(%MonState{} = monstate) do
    %Serialized{
      mcu_params:
        monstate.hardware.mcu_params,
      location:
        monstate.hardware.location,
      pins:
        monstate.hardware.pins,
      configuration:
        Map.delete(monstate.configuration.configuration, :user_env),
      informational_settings:
        monstate.configuration.informational_settings,
      process_info:
        monstate.process_info,
      user_env:
        monstate.configuration.configuration.user_env
    }
  end

  # Emit a message
  def handle_cast({:emit, thing}, state) do
    # don't Logger this because it will infinate loop.
    # just trust me.
    # logging a message here would cause logger to log a message, which
    # causes a state send which would then emit a message...
    IO.puts "emmitting: #{inspect thing}"
    GenStage.async_notify(__MODULE__, {:emit, thing})
    {:noreply, [], state}
  end

  # Emit a log message
  def handle_cast({:log, log}, state) do
    GenStage.async_notify(__MODULE__, {:log, log})
    {:noreply, [], state}
  end

  def handle_info({_from, %MonState{} = monstate}, old_state) do
    new_state = translate(monstate)
    if (old_state == new_state) && (get_count() < @max_inactive_count) do
      inc_count()
      {:noreply, [], old_state}
    else
      # dec_count() # HACK(Connor) Dialyzer hack
      reset_count()
      GenStage.async_notify(__MODULE__, {:status, new_state})
      {:noreply, [], new_state}
    end
  end

  def handle_info(_event, state), do: {:noreply, [], state}

  @doc """
    Emit a message over all transports
  """
  @spec emit(any) :: no_return
  def emit(message), do: GenStage.cast(__MODULE__, {:emit, message})

  @doc """
    Log a log message over all transports
  """
  @spec log(any) :: no_return
  def log(message), do: GenStage.cast(__MODULE__, {:log, message})

  @doc """
    Get the state
  """
  @spec get_state :: State.t
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @doc """
    Force a state push
  """
  @spec force_state_push :: State.t
  def force_state_push, do: GenServer.call(__MODULE__, :force_state_push)
end
