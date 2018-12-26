defmodule NodesTest.Node do
  alias NodesTest.NodeManager
  use GenServer

  #client

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def get_state(name) do
    GenServer.call(name, {:get_state})
  end

  def update_state(name, new_state) when new_state == %{} do
    GenServer.call(name, {:update_state_init, new_state})
  end

  def update_state(name, new_state) do
    GenServer.call(name, {:update_state, new_state})
  end

  def start_election(pid) do
    GenServer.call(pid, {:start_election})
  end

  def start_ping(pid) do
    GenServer.call(pid, {:start_ping})
  end

  def ping(pid) do
    GenServer.call(pid, {:ping}, 3000)
  end

  def send_alive?(pid) do
    GenServer.call(pid, {:alive?})
  end

  def kill_process(pid) do
    Process.send(pid, :kill_me_pls, [:noconnect])
  end

  #server

  def handle_call({:get_state}, from, state) do
    IO.inspect from, label: "From"
    {:reply, state, state}
  end

  def handle_call({:update_state, new_state}, _, _) do
    self_pid = self()
    filtered_state = Enum.filter new_state, fn {pid, _} -> pid != self_pid end
    new_state = Map.new(filtered_state)
    {:reply, new_state, new_state}
  end

  def handle_call({:update_state_init, new_state}, _, _) do
    {:reply, new_state, new_state}
  end

  defp election([node | nodes], true) when self() < node do
    try do
      send_alive?(node)
      election(nodes, true)
    catch
      :exit, _ ->
        election(nodes, true)
    end
  end

  defp election([node | nodes], true) when self() > node do
    election(nodes, true)
  end

  defp election([], true) do
    :ok
  end

  def handle_call({:start_election}, _, state) do
    if Enum.max(Map.keys(state)) < self() do
      for {p, _} <- state do
        Process.send(p, {:iamtheking, self()}, [:noconnect])
      end
      Process.send(self(), {:iamtheking, self()}, [:noconnect])
    else
      Process.send(self(), {:start_election, :async}, [:nosuspend])
    end
    {:reply, :ok, state}
  end

  def handle_call({:start_ping}, _, state) do
    Process.send(self(), :start_ping, [:noconnect])
    {:reply, :ok, state}
  end

  def handle_call({:ping}, _, state) do
    {:reply, :ok, state}
  end

  def handle_info(:kill_me_pls, state) do
    for {p, _} <- state do
      Process.send(p, {:delete_node, self()}, [:noconnect])
    end
    {:stop, :normal, state}
  end

  def handle_info({:delete_node, pid}, state) do
    new_state = Map.delete(state, pid)
    {:noreply, new_state}
  end

  def handle_info(:start_ping, state) do
    first_pid = Map.keys(state) |> List.first()
    leader_pid = state[first_pid].leader
    pinging(leader_pid, self())
    {:noreply, state}
  end

  defp pinging(leader_pid, self_pid) do
    try do
      :ok = ping(leader_pid)
      IO.inspect self_pid
      Process.send_after(self_pid, :start_ping, 3000)
    catch
      :exit, _ ->
        Process.send(self_pid, {:start_election, :async}, [:noconnect])
    end
    :ok
  end

  def handle_info({:start_election, :async}, state) do
    election(Map.keys(state), true)
    {:noreply, state}
  end

  def handle_info({:iamtheking, pid}, state) do
    new_state = Enum.reduce(state, state, fn {p, _}, acc ->
      put_in(acc, [p, :leader], pid)
    end)

    Process.send(self(), :start_ping, [:noconnect])
    {:noreply, new_state}
  end

  def handle_info({:finethanks, pid}, state) do
    IO.inspect "finethanks"
    start_election(pid)
    {:noreply, state}
  end

  def handle_info(reply, state) do
    {:noreply, state}
  end

  def handle_call({:alive?}, {pid, _}, state) do
    if self() > Enum.max(Map.keys(state)) do
      for {p, _} <- state do
        Process.send(p, {:iamtheking, self()}, [:noconnect])
      end
      Process.send(self(), {:iamtheking, self()}, [:noconnect])
      {:reply, :iamtheking, state}
    else
      Process.send(pid, {:finethanks, self()}, [:noconnect])
      {:reply, :finethanks, state}
    end
  end
end
