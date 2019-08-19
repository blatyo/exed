defmodule Exed.Native.Command do
  use Rustler, otp_app: :exed
  import Kernel, except: [to_string: 1]

  defstruct [:binary, :args, :envs, :current_dir]

  def from_command(%Exed.Command{} = cmd) do
    %__MODULE__{
      binary: cmd.binary,
      args: to_simple_args(cmd.args),
      current_dir: cmd.current_dir,
      envs: cmd.envs
    }
  end

  defp to_simple_args(args) do
    args
    |> Enum.reverse()
    |> Enum.map(fn
      {flag, true} ->
        flag

      {flag, value} ->
        if String.starts_with?(flag, "--") do
          flag <> "=" <> value
        else
          [flag, value]
        end

      arg ->
        arg
    end)
    |> List.flatten()
  end

  def to_string(_command), do: error!()

  defp error!, do: :erlang.nif_error(:nif_not_loaded)
end
