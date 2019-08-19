defmodule Exed.Command do
  defstruct [:binary, :current_dir, args: [], envs: %{}]

  @opaque t :: %__MODULE__{
            binary: String.t(),
            args: [String.t() | {String.t(), String.t() | boolean}],
            current_dir: nil | String.t(),
            envs: Map.t(String.t(), String.t())
          }

  @type args :: list
  @type flag :: atom | String.t()

  @spec new(String.t() | atom) :: t
  def new(binary) do
    %__MODULE__{binary: to_string(binary)}
  end

  def current_dir(%__MODULE__{} = cmd, current_dir)
      when is_binary(current_dir) or current_dir == nil do
    %{cmd | current_dir: current_dir}
  end

  def env(%__MODULE__{} = cmd, name, value) do
    %{cmd | envs: Map.put(cmd.envs, to_string(name), to_string(value))}
  end

  def delete_env(%__MODULE__{} = cmd, name) do
    %{cmd | envs: Map.delete(cmd.envs, to_string(name))}
  end

  def clear_envs(%__MODULE__{} = cmd) do
    %{cmd | envs: %{}}
  end

  def envs(%__MODULE__{} = cmd, envs) when is_map(envs) do
    Enum.reduce(envs, cmd, fn {name, value}, cmd ->
      env(cmd, name, value)
    end)
  end

  @spec flags(t, map | keyword) :: t
  def flags(%__MODULE__{} = cmd, flags) when is_list(flags) do
    Enum.reduce(flags, cmd, fn
      {flag, value}, cmd -> flag(cmd, flag, value)
      flag, cmd -> flag(cmd, flag)
    end)
  end

  def flags(%__MODULE__{} = cmd, %{} = flags) do
    flags(cmd, Map.to_list(flags))
  end

  @spec flag(t, flag) :: t
  def flag(%__MODULE__{} = cmd, flag) when is_atom(flag) do
    flag(cmd, flag, true)
  end

  def flag(%__MODULE__{} = cmd, flag) when is_binary(flag) do
    flag(cmd, flag, true)
  end

  @spec flag(t(), flag, any) :: t()
  def flag(%__MODULE__{} = cmd, flag, value) when is_binary(flag) do
    flag
    |> to_flag()
    |> case do
      {:ok, flag} ->
        raw_arg(cmd, {flag, value})

      {:error, reason} ->
        raise ArgumentError, reason <> " Perhaps you want Exec.Cmd.append_arg/2"
    end
  end

  def flag(%__MODULE__{} = cmd, flag_name, value) when is_atom(flag_name) do
    flag_name
    |> to_flag()
    |> case do
      {:ok, flag} -> flag(cmd, flag, value)
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @spec args(t, [term]) :: t
  def args(cmd, args) when is_list(args) do
    Enum.reduce(args, cmd, fn arg, cmd ->
      arg(cmd, arg)
    end)
  end

  @spec arg(t, any) :: t()
  def arg(%__MODULE__{} = cmd, arg) do
    raw_arg(cmd, to_string(arg))
  end

  defp raw_arg(cmd, arg) do
    %{cmd | args: [arg | cmd.args]}
  end

  defp to_flag(flag) when is_binary(flag) do
    if String.starts_with?(flag, "-") do
      {:ok, flag}
    else
      {:error, "Expected flag to start with - or --, got #{inspect(flag)}."}
    end
  end

  defp to_flag(flag_name) when is_atom(flag_name) do
    flag = to_string(flag_name)

    case {String.length(flag), String.starts_with?(flag, "-")} do
      {1, false} ->
        {:ok, "-" <> flag}

      {length, false} when length > 1 ->
        {:ok, "--" <> flag}

      {_, false} ->
        {:error, "Expected flag with with length 1 or greater, got #{inspect(flag_name)}."}

      {_, true} ->
        {:error,
         "When passing an atom for a flag name, avoid prefixing with dashes (-) or pass a string instead."}
    end
  end
end

defimpl Inspect, for: Exed.Command do
  import Inspect.Algebra

  def inspect(cmd, _opts) do
    concat(["#Exed.Command<", to_string(cmd), ">"])
  end
end

defimpl String.Chars, for: Exed.Command do
  def to_string(cmd) do
    alias Exed.Native.Command, as: Native

    cmd
    |> Native.from_command()
    |> Native.to_string()
  end
end
