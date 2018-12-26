defmodule NodesTest.NodeManager do
  alias NodesTest.Node
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def new_node() do
    {new_state, pid} = GenServer.call(__MODULE__, {:new_node})
    IO.inspect length(Map.keys(new_state))
    if length(Map.keys(new_state)) > 1 do
      Enum.each(new_state, fn {_, info} ->
        Node.update_state(info.name, new_state)
      end)
      Node.start_election(pid)
    else
      Node.update_state(pid, %{})
    end
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  def handle_call({:get_state}, _, state) do
    {:reply, state, state}
  end

  def handle_call({:new_node}, _, state) when state == %{} do
    {:ok, pid} = Node.start_link(:node1)
    new_state = %{
      pid => %{
        name: :node1,
        leader: pid,
      }
    }
    {:reply, {new_state, pid}, new_state}
  end

  def handle_call({:new_node}, _, state) do
    node_count = (Map.keys(state) |> length()) + 1
    node_name = String.to_atom("node#{node_count}")
    {:ok, pid} = Node.start_link(node_name)
    new_state = Map.put(state, pid, %{
      name: node_name,
      leader: node_name
    })
    {:reply, {new_state, pid}, new_state}
  end
end
