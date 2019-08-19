defmodule Exed.CommandTest do
  use ExUnit.Case, async: true
  import Exed.Command

  @expected_docker_command ~s["docker" "run" "-i" "-t" "--rm" "--expose=8000:8000" "--expose=8001:8001" "bash" "ls" "-l" "-a"]
  defp docker_command do
    new(:docker)
    |> arg(:run)
    |> flags(~w[i t rm]a)
    |> flags(expose: "8000:8000", expose: "8001:8001")
    |> arg("bash")
    |> arg(:ls)
    |> flags(~w[l a]a)
  end

  @expected_git_command ~s["git" "log" "--color" "--graph" "--abbrev-commit" "--pretty=format:\\'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\\'" "--"]
  defp git_command do
    new(:git)
    |> arg(:log)
    |> flags(~w[color graph abbrev-commit]a)
    |> flag(
      :pretty,
      "format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
    )
    |> arg("--")
  end

  @expected_java_command ~s["java" "-jar" "-Xmx80m" "app.jar"]
  defp java_command do
    new(:java)
    |> flags(~w[-jar -Xmx80m])
    |> arg("app.jar")
  end

  describe "to_string/1" do
    test "generates expected commands" do
      assert to_string(docker_command()) == @expected_docker_command
      assert to_string(git_command()) == @expected_git_command
      assert to_string(java_command()) == @expected_java_command
    end
  end

  describe "inspect/1" do
    test "shows command" do
      assert inspect(docker_command()) == "#Exed.Command<#{@expected_docker_command}>"
      assert inspect(git_command()) == "#Exed.Command<#{@expected_git_command}>"
      assert inspect(java_command()) == "#Exed.Command<#{@expected_java_command}>"
    end
  end
end
