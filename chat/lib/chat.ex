defmodule Chat.Server do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, {Map.new(), Map.new()}, name: __MODULE__)
  end

  def name_socket(name, socket) do
    GenServer.call(__MODULE__, {:name_socket, name, socket})
  end

  def get_socket(name) do
    GenServer.call(__MODULE__, {:get_socket, name})
  end

  def get_name(socket) do
    GenServer.call(__MODULE__, {:get_name, socket})
  end

  def get_all() do
    GenServer.call(__MODULE__, {:get_all})
  end

  def delete_name(socket) do
    GenServer.cast(__MODULE__, {:delete_name, socket})
  end

  def delete_socket(name) do
    GenServer.cast(__MODULE__, {:delete_socket, name})
  end

	@impl true
	def init(maps) do
    Chat.Proxy.start()
		{:ok, maps}
	end

  @impl true
  def handle_call({:name_socket, name, socket}, _from, {name_sock, sock_name}) do
    if Map.has_key?(sock_name, socket) do
      name_to_delete = Map.get(sock_name, socket)
      new_name_sock = Map.delete(name_sock, name_to_delete)
      IO.puts("#{Map.get(sock_name, socket)} removed!")
      new_new_name_sock = Map.put(new_name_sock, name, socket)
      new_sock_name = Map.put(sock_name, socket, name)
      {:reply, :ok, {new_new_name_sock, new_sock_name}}
    else
      new_name_sock = Map.put(name_sock, name, socket)
      new_sock_name = Map.put(sock_name, socket, name)
      {:reply, :ok, {new_name_sock, new_sock_name}}
    end
  end

  @impl true
  def handle_call({:get_socket, name}, _from, {name_sock, sock_name}) do
    {:reply, (Map.get(name_sock, name)), {name_sock, sock_name}}
  end

  @impl true
  def handle_call({:get_name, socket}, _from, {name_sock, sock_name}) do
    {:reply, (Map.get(sock_name, socket)), {name_sock, sock_name}}
  end

  @impl true
  def handle_call({:get_all}, _from, {name_sock, sock_name}) do
    {:reply, (Map.keys(name_sock)), {name_sock, sock_name}}
  end
  
  @impl true
  def handle_cast({:delete_name, socket}, {name_sock, sock_name}) do
    new_name_sock = Map.delete(name_sock, socket)
    {:noreply, {new_name_sock, sock_name}}
  end
  
  @impl true
  def handle_cast({:delete_socket, name}, {name_sock, sock_name}) do
    new_sock_name = Map.delete(sock_name, name)
    {:noreply, {name_sock, new_sock_name}}
  end
end

defmodule Chat.Proxy do
  def start(port \\ 6666) do
    opts = [:binary, {:active, false}, {:packet, 0}, {:reuseaddr, true}]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    spawn(fn -> accept_client(socket) end)
  end

  def accept_client(socket) do
    {:ok, connected_socket} = :gen_tcp.accept(socket)
    spawn(fn -> accept_client(socket) end)
    loop(connected_socket)
  end

  def loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, bin} ->
        IO.puts(bin)
        process_input(socket, bin)
        loop(socket)
      {:error, :closed} ->
        name_to_delete = Chat.Server.get_name(socket)
        Chat.Server.delete_name(name_to_delete)
        Chat.Server.delete_socket(socket)
        IO.puts("#{name_to_delete} removed!")
        send_to_sockets(Chat.Server.get_all(), "#{name_to_delete} has left the chat!", "Server")
        :gen_tcp.close(socket)
    end
  end

  def get_message([x | xs], message) do
    if xs == [] do
      {_, final_message} = String.split_at("#{message} #{x}", 1)
      final_message
    else
      get_message(xs, "#{message} #{x}")
    end
  end

  def send_to_sockets([x | xs], message, name) do
    socket = Chat.Server.get_socket(x)
    if socket != nil do
      IO.puts("Sending message to #{x}: #{name}: #{message}")
      :gen_tcp.send(socket, "#{name}: #{message}\n")
      if xs != [] do
        send_to_sockets(xs, message, name)
      end
    else
      if xs != [] do
        send_to_sockets(xs, message, name)
      end
    end
  end

  def send_to_sockets([], _message, _name) do
    :ok
  end

  def process_input(socket, input) do
    input_list = String.split(input)
    {command, input_list} = List.pop_at(input_list, 0)
    if command == nil do
      :gen_tcp.send(socket, input)
    else
      case String.downcase(command) do
        "/nick" ->
          case Enum.count(input_list) do
            1 ->
              {name, _} = List.pop_at(input_list, 0)
              if validate_nick(name) do
                existing = Chat.Server.get_socket(name)
                if existing == nil do
                  existing_socket_name = Chat.Server.get_name(socket)
                  if existing_socket_name != nil do
                    send_to_sockets(Chat.Server.get_all(), "#{existing_socket_name} has left the chat!", "Server")
                  end
                  Chat.Server.name_socket(name, socket)
                  IO.puts("Name successfully set!")
                  send_to_sockets(Chat.Server.get_all(), "#{name} has joined the chat!", "Server")
                  "Name successfully set!"
                else
                  :gen_tcp.send(socket, "Error! Name is already taken!!\n")
                end
              else
                :gen_tcp.send(socket, "Error! Name is not valid!!\n")
              end
              
            _ ->
              :gen_tcp.send(socket, "Error! Command is not valid!\n")
          end
        "/msg" ->
          case Enum.count(input_list) do
            0 ->
              :gen_tcp.send(socket, "Error! Command is not valid!\n")
            1 ->
              :gen_tcp.send(socket, "Error! Command is not valid!\n")
            _ ->
              if Chat.Server.get_name(socket) == nil do
                :gen_tcp.send(socket, "Error! Cannot send message without first initializing nickname!\n")
              else
                {users_string, input_list} = List.pop_at(input_list, 0)
                if users_string == ";" do
                  send_to_sockets(Chat.Server.get_all(), get_message(input_list, ""), Chat.Server.get_name(socket))
                  :gen_tcp.send(socket, "Sent message to everyone!\n")
                else
                  users = String.split(users_string, ",")
                  send_to_sockets(users, get_message(input_list, ""), Chat.Server.get_name(socket))
                  :gen_tcp.send(socket, "Sent message to #{users_string}!\n")
                end
              end
          end
        _ ->
          :gen_tcp.send(socket, "Error! invalid commands!!\n")
      end
    end
  end

  def validate_nick(name) do
    name = String.replace(name, "_", "")
    if String.match?(name, ~r/^[[:alnum:]]+$/i) && String.length(name) <= 9 && String.match?(String.slice(name, 0, 1), ~r/^[[:alpha:]]+$/i) do
      true
    else
      false
    end
  end
end
