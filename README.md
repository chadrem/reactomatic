# Reactomatic

Reactomatic is an implementation of the [Reactor Pattern](https://en.wikipedia.org/wiki/Reactor_pattern) for Ruby.
It's built on top of the excellent [nio4r](https://github.com/celluloid/nio4r) gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reactomatic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reactomatic


## Reactors

The ````Reactor```` class is the heart of Reactomatic.
Reactors handle all the low level details of running an event loop in a dedicated thread.
This means you get to focus on writing application logic instead of low level socket code.

Reactomatic creates a default reactor that should be sufficient for most applications (you can also create custom ones):

    Reactomatic.reactor
    
*Instance methods:*

- ````stop````: Stop the reactor and its dedicated thread.  This doesn't close any open connections or running servers.
- ````start````: Start the reactor and its dedicated thread.
- ````next_tick````: Runs a block of code on the reactor's thread in the future (next time it loops).
- ````schedule````: Runs a block of code on the reactor's thread immediately if called from the reactor thread or schedules it to run in the future with ````next_tick````.

## TCP Servers

The ````TcpServer```` class lets you easily listen for new connections and pass them off to a connection class.
Here is an example:

    server = TcpServer.new
    server.listen('0.0.0.0', 9000, Reactomatic::TcpConnection)

The above code will listen for new connections on ````0.0.0.0:9000````.
When it receives one, it will create an instance of ````Reactomatic::TcpConnection```` to process data associated with the connection.  Below you will learn how to create your own custom connection class to override the default behavior.

*Instance methods:*

- ````listen(host, port, klass)````: Listen for incoming connections.
- ````close````: Stop listening for incoming connections.  Already established connections will remain open.

## TCP Connections

The ````TcpConnection```` base class is how you interface your application logic with sending and receiving data.
It's designed so that your custom connection classes inherit from it and override event handlers.
Here's an example:

    class MyConnection < Reactomatic::TcpConnection
    private
    def on_initialize
      puts "MyConnection: initialized!"
    end

    def on_receive_data(data)
      puts "MyConnection: received #{data.bytesize} bytes of data and echoing back!"
      send_data(data)
    end

    def on_sent_data(num_bytes)
      puts "MyConnection: sent #{num_bytes} of data!"
    end

    def on_disconnect
      puts "MyConnection: disconnected!"
    end
    end

*Instance methods:*

- ````reactor````: Returns a reference to this connections reactor.
- ````send_data(data)````: Queues data for sending.  If it can't be sent immediately, the data will be buffered and sent in the future.
- ````close````: Immediately closes the connection.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reactomatic.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

