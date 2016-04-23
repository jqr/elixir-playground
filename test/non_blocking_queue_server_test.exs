# Implements a striclty non-blocking FIFO queue.
#
# Uses a single array holding waiting items.
defmodule NonBlockingQueueServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(queue) do
    {:ok, queue}
  end

  def handle_call({:put, value}, _from, queue) do
    {:reply, :ok, queue ++ [value]}
  end
  def handle_call({:pop}, _from, [value | queue]) do
    {:reply, {:ok, value}, queue}
  end
  def handle_call({:pop}, _from, []) do
    {:reply, :empty, []}
  end

  def handle_cast({:aput, value}, queue) do
    {:noreply, queue ++ [value]}
  end

  # Synchonously puts data into the qeueue.
  # Returns :ok on success
  def put(command_queue, value) do
    GenServer.call(command_queue, {:put, value})
  end

  # Asynchonously puts data into the qeueue.
  # Returns nothing
  def aput(command_queue, value) do
    GenServer.cast(command_queue, {:aput, value})
  end

  # Synchronously pops data from the queue.
  # Returns {:ok, value} on success
  # Returns {:ok, nil} on empty queue
  def pop(command_queue) do
    GenServer.call(command_queue, {:pop})
  end
end

defmodule NonBlockingQueueServerTest do
  use ExUnit.Case, async: true

  # :dbg.tracer
  # :dbg.p self()

  setup do
    {:ok, queue} = NonBlockingQueueServer.start_link
    {:ok, [queue: queue]}
  end

  test "pop when empty", %{queue: queue} do
    :empty = NonBlockingQueueServer.pop(queue)
  end

  test "put", %{queue: queue} do
    :ok = NonBlockingQueueServer.put(queue, "hello")
  end

  test "put, pop", %{queue: queue} do
    :ok = NonBlockingQueueServer.put(queue, "hello")
    {:ok, "hello"} = NonBlockingQueueServer.pop(queue)
  end

  test "put, put, pop, pop maintains FIFO", %{queue: queue} do
    :ok = NonBlockingQueueServer.put(queue, "hello")
    :ok = NonBlockingQueueServer.put(queue, "world")

    {:ok, "hello"} = NonBlockingQueueServer.pop(queue)
    {:ok, "world"} = NonBlockingQueueServer.pop(queue)
  end

  test "aput", %{queue: queue} do
    :ok = NonBlockingQueueServer.aput(queue, "hello")
  end

  test "aput, pop", %{queue: queue} do
    :ok = NonBlockingQueueServer.aput(queue, "hello")
    {:ok, "hello"} = NonBlockingQueueServer.pop(queue)
  end

  test "aput, aput, pop, pop maintains FIFO", %{queue: queue} do
    :ok = NonBlockingQueueServer.aput(queue, "hello")
    :ok = NonBlockingQueueServer.aput(queue, "world")

    {:ok, "hello"} = NonBlockingQueueServer.pop(queue)
    {:ok, "world"} = NonBlockingQueueServer.pop(queue)
  end
end
