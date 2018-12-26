# NodesTest

## How to run

1. mix deps.get
2. iex -S mix

## Commands for test

```elixir
# Run the nodes
1. NodesTest.NodeManager.start_link # starting the server(only once)
2. NodesTest.NodeManager.new_node # run the node(multiple times to add some number of nodes)
# After running this the nodes start leader election. 

# Check the state of the node to see the leader
NodesTest.Node.get_state(node_name) # node names are initialized automaticaly when creating them (:node1, :node2, etc.)

# To kill the node
NodesTest.Node.kill_process(pid)
```

