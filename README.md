
# Elixir Chat Messaging Server

### How do I start the server and client(s)?

1. Ensure you have properly installed Elixir. 

2. Navigate to "/chat" and generate the elixir application by running this command in the terminal
    ```iex -S mix```

*This should have installed all dependencies as well.

3. Start the Chat Server by inputting the following command in iex:
	```Chat.Server.start_link()```

4. If you get an :ok response message, with the PID of the server you just started, the server has successfully been started!

### Starting the client(s)

1. Compile ChatClient.java by navigating running the following command in the directory in which your client is situated in:
	```javac ChatClient.java```

2. Run the client by running this command in the same directory:
	```java ChatClient```
	
3. If the following output is 
	```> ```
You've successfully started the client!

To message other users on the same network, simply initialize your nickname by inputting 
	```> /nick {nickname}```
	
...and to message other users, input
	```> /msg {nickname} {msg}```

Enjoy chatting!
