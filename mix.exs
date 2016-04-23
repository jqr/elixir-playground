defmodule Instrumental.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elixir_playground,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      package: package,
      description: description,
    ]
  end

  def application do
    [
      # mod: {Instrumental, []},
      applications: [
        :logger
      ],
      registered: [
        # Instrumental.Supervisor,
        # Instrumental.Connection,
      ],
      env: [
        # host: "collector.instrumentalapp.com",
        # port: 8000,
        # token: "",
      ],
    ]
  end

  defp deps do
    []
  end

  defp description do
    """
    """
  end

  defp package do
    %{licenses: ["MIT"],
      contributors: ["Elijah Miller"],
      links: %{"Github" => "https://github.com/jqr/elixir-playground"}}
  end
end
