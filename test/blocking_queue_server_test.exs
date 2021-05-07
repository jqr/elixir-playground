# Implements a striclty blocking FIFO queue.
#
# As values are put, they are added to an array. Any pops will cause immediate
# dequeuing from this array.
#
# As values are popped, the popper is added to an array. Any puts will cause
# immediate dequeuing from this array and values will be delivered to waiting
# poppers.
#
# In this way, the two arrays hold waiting items or waiting readers. At any
# given point only one of these arrays should have any items.
defmodule BlockingQueueServer do
  use GenServer

  defmodule State do
    defstruct queue: [], waiters: []
  end

  def start_link do
    GenServer.start_link(__MODULE__, %State{})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:put, value}, _from, %{queue: [], waiters: [waiter | waiters]} = state) do
    GenServer.reply(waiter, {:ok, value})
    {:reply, :ok, %{state | waiters: waiters}}
  end
  def handle_call({:put, value}, _from, %{queue: queue, waiters: []} = state) do
    {:reply, :ok, %{state | queue: queue ++ [value]}}
  end
  def handle_call({:pop}, _from, %{queue: [value | queue]} = state) do
    {:reply, {:ok, value}, %{state | queue: queue}}
  end
  def handle_call({:pop}, from, %{queue: [], waiters: waiters} = state) do
    {:noreply, %{state | waiters: waiters ++ [from]}}
  end

  def handle_cast({:aput, value}, %{queue: [], waiters: [waiter | waiters]} = state) do
    GenServer.reply(waiter, {:ok, value})
    {:noreply, %{state | waiters: waiters}}
  end
  def handle_cast({:aput, value}, %{queue: queue, waiters: []} = state) do
    {:noreply, %{state | queue: queue ++ [value]}}
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
  # Returns {:timeout} on timeout
  def pop(command_queue, timeout) do
    try do
      GenServer.call(command_queue, {:pop}, timeout)
    catch
      :exit, _ -> :timeout
    end
  end
  def pop(command_queue) do
    pop(command_queue, 5000)
  end
end

defmodule BlockingQueueServerTest do
  use ExUnit.Case, async: true

  # :dbg.tracer
  # :dbg.p self()

  defp wait do
    :timer.sleep(10)
  end

  setup do
    {:ok, queue} = BlockingQueueServer.start_link
    {:ok, [queue: queue]}
  end

  test "pop when empty with timeout", %{queue: queue} do
    :timeout = BlockingQueueServer.pop(queue, 1)
  end

  test "put", %{queue: queue} do
    :ok = BlockingQueueServer.put(queue, "hello")
  end

  test "put, pop", %{queue: queue} do
    :ok = BlockingQueueServer.put(queue, "hello")
    {:ok, "hello"} = BlockingQueueServer.pop(queue)
  end

  test "pop, put", %{queue: queue} do
    spawn_link fn ->
      {:ok, "hello"} = BlockingQueueServer.pop(queue)
    end
    wait()
    :ok = BlockingQueueServer.put(queue, "hello")
  end

  test "put, put, pop, pop maintains FIFO", %{queue: queue} do
    :ok = BlockingQueueServer.put(queue, "hello")
    :ok = BlockingQueueServer.put(queue, "world")

    {:ok, "hello"} = BlockingQueueServer.pop(queue)
    {:ok, "world"} = BlockingQueueServer.pop(queue)
  end

  test "pop, pop, put, put maintains FIFO", %{queue: queue} do
    spawn_link fn ->
      {:ok, "hello"} = BlockingQueueServer.pop(queue)
    end
    wait()
    spawn_link fn ->
      {:ok, "world"} = BlockingQueueServer.pop(queue)
    end
    wait()
    :ok = BlockingQueueServer.put(queue, "hello")
    :ok = BlockingQueueServer.put(queue, "world")
  end

  test "aput", %{queue: queue} do
    :ok = BlockingQueueServer.aput(queue, "hello")
  end

  test "aput, pop", %{queue: queue} do
    :ok = BlockingQueueServer.aput(queue, "hello")
    {:ok, "hello"} = BlockingQueueServer.pop(queue)
  end

  test "pop, aput", %{queue: queue} do
    spawn_link fn ->
      {:ok, "hello"} = BlockingQueueServer.pop(queue)
    end
    wait()
    :ok = BlockingQueueServer.aput(queue, "hello")
  end

  test "aput, aput, pop, pop maintains FIFO", %{queue: queue} do
    :ok = BlockingQueueServer.aput(queue, "hello")
    :ok = BlockingQueueServer.aput(queue, "world")

    {:ok, "hello"} = BlockingQueueServer.pop(queue)
    {:ok, "world"} = BlockingQueueServer.pop(queue)
  end

  test "pop, pop, aput, aput maintains FIFO", %{queue: queue} do
    spawn_link fn ->
      {:ok, "hello"} = BlockingQueueServer.pop(queue)
    end
    wait()
    spawn_link fn ->
      {:ok, "world"} = BlockingQueueServer.pop(queue)
    end
    wait()
    :ok = BlockingQueueServer.aput(queue, "hello")
    :ok = BlockingQueueServer.aput(queue, "world")
  end

end
