defmodule Farmbot.Mixfile do
  use Mix.Project
  @target System.get_env("MIX_TARGET") || "host"
  @version Path.join(__DIR__, "VERSION") |> File.read! |> String.strip
  @compat_version Path.join(__DIR__, "COMPAT")
    |> File.read!
    |> String.strip
    |> String.to_integer

  defp commit() do
    {t,_} = System.cmd("git", ["log", "--pretty=format:%h", "-1"])
    t
  end

  def project do
    [app: :farmbot,
     description: "The Brains of the Farmbot Project",
     package: package(),
     test_coverage: [tool: ExCoveralls],
     version: @version,
     target: @target,
     archives: [nerves_bootstrap: "~> 0.3.0"],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     build_path: "_build/#{@target}",
     deps_path: "deps/#{@target}",
     images_path: "images/#{@target}", # this doesnt work on current version of nerves
     config_path: "config/config.exs",
     lockfile: "mix.lock",
     compilers: Mix.compilers ++ maybe_use_webpack(),
     aliases: aliases(@target),
     deps: deps() ++ system(@target),
     dialyzer: [plt_add_deps: :app_tree, plt_add_apps: [:mnesia, :hackney]],
     preferred_cli_env: [
       vcr: :test, "vcr.delete": :test, "vcr.check": :test, "vcr.show": :test,
       "all_test": :test,
       "coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test, "coveralls.travis": :test
     ],
     webpack_watch: Mix.env == :dev,
     webpack_cd: ".",
     source_url: "https://github.com/Farmbot/farmbot_os",
     homepage_url: "http://farmbot.io",
     docs: [main: "Farmbot",
            logo: "../../docs/farmbot_logo.png",
            extras: ["../../docs/BUILDING.md",
              "../../docs/FAQ.md",
              "../../docs/ENVIRONMENT.md",
              "../../README.md"]]
   ]
  end

  def package do
    [name: "Farmbot OS",
    maintainers: "Farmbot.io",
    licenses: "MIT"]
  end

  def application do
    [mod:
      {Farmbot,
       [%{target: @target,
          compat_version: @compat_version,
          version: @version,
          commit: commit()}]},
     applications: applications() ++ applications(@target),
     included_applications: [:gen_mqtt, :ex_json_schema, :fs] ++ included_apps(Mix.env)]
  end

  defp included_apps(:prod), do: [:ex_syslogger]
  defp included_apps(_), do: []

  # common for test, prod, and dev
  defp applications do
    [
      :logger,
      :nerves_uart,
      :poison,
      :rsa,
      :httpoison,
      :nerves_lib,
      :runtime_tools,
      :mustache,
      :vmq_commons,
      :amnesia,
      :gen_stage,
      :plug,
      :cors_plug,
      :cowboy,
      :quantum, # Quantum needs to start AFTER farmbot, so we can set up its dirs
      :timex, # Timex needs to start AFTER farmbot, so we can set up its dirs,
      :inets,
      :redix,
      :eex
   ]
  end

  defp applications("host"), do: []
  defp applications(_system), do: [
    :nerves_interim_wifi,
    :nerves_firmware_http,
    :nerves_firmware,
    :nerves_ssdp_server
  ]

  defp deps do
    [
      # Hardware stuff
      {:nerves_uart, "0.1.1"}, # uart handling
      {:nerves_lib, github: "nerves-project/nerves_lib"}, # this has a good uuid

      # http stuff
      {:poison, "~> 3.0"},
      {:ex_json_schema, "~> 0.5.3"},
      {:exjsx, "~> 3.2", override: true},
      {:httpoison, github: "edgurgel/httpoison", override: true},
      {:rsa, "~> 0.0.1"},

      # MQTT stuff
      {:gen_mqtt, "~> 0.3.1"}, # for rpc transport
      {:vmq_commons, "1.0.0", manager: :rebar3}, # This is for mqtt to work.

      # string templating
      {:mustache, "~> 0.0.2"},

      # Time stuff
      {:timex, "~> 3.0"}, # managing time. for the scheduler mostly.
      {:quantum, ">= 1.8.1"}, # cron jobs

      # Database
      {:amnesia, github: "meh/amnesia"}, # database implementation
      {:redix, ">= 0.0.0"},

      # Log to syslog
      {:ex_syslogger, "~> 1.3.3", only: :prod},

      # Other stuff
      {:gen_stage, "0.11.0"},

      # Test/Dev only
      {:credo, "0.6.0-rc1",  only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:faker, "~> 0.7", only: :test},
      {:excoveralls, "~> 0.6", only: :test},
      {:exvcr, "~> 0.8", only: :test},
      {:mock, "~> 0.2.0", only: :test},

      # Web stuff
      {:plug, "~> 1.0"},
      {:cors_plug, "~> 1.1"},
      {:cowboy, "~> 1.0.0"},
      {:ex_webpack, "~> 0.1.1", runtime: false, warn_missing: false},

      {:tzdata, "~> 0.1.201601", override: true},
      {:fs, "~> 0.9.1"}
    ]
  end


  # TODO(connor): Build this into `:ex_webpack`
  defp maybe_use_webpack() do
    case System.get_env("NO_WEBPACK") do
      "true" -> []
      _ -> [:ex_webpack]
    end
  end


  # this is for cross compilation to work
  # New version of nerves might not need this?
  defp aliases("host"), do: [
    "firmware": ["compile"],
    "firmware.push": ["farmbot.warning"],
    "credo": ["credo list --only readability,warning,todo,inspect,refactor --ignore-checks todo,spec"],
    "all_test": ["credo", "coveralls"],
    "travis_test": ["credo", "coveralls.travis"]
  ]

  # TODO(Connor) Maybe warn if building firmware in dev mode?
  defp aliases(_system) do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"],
     "firmware.upload": ["farmbot.upload"]]
  end

  # the nerves_system_* dir to use for this build.
  defp system("host"), do: []
  defp system(sys) do
    if File.exists?("nerves/NERVES_SYSTEM_#{sys}"),
      do: System.put_env("NERVES_SYSTEM", Path.absname("nerves/NERVES_SYSTEM_#{sys}", File.cwd!)),
    else: raise "EFFFFFFF"

    # if the system is local (because we have changes to it) use that
    if File.exists?("nerves/nerves_system_#{sys}"),
      do: [
        {:"nerves_system_#{sys}", warn_missing: false, path: "nerves/nerves_system_#{sys}"},
        {:nerves_interim_wifi, "~> 0.1.1"},
        # {:nerves_firmware_http, github: "nerves-project/nerves_firmware_http"},
        {:nerves_firmware_http, "~> 0.3.1"},
        {:nerves_firmware, "~> 0.3"},
        {:nerves_ssdp_server, "~> 0.2.1"},
        ],
      else: Mix.raise("There is no existing system package for #{sys}")
  end
end
