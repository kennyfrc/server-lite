## Server Lite

Simple, non-spec compliant, & insecure web server made for learning purposes.

That can serve files off disk and execute scripts when marked as executable.


### Dependencies

```
socket
```

### General Steps

1. Create a socket using IPv4 and TCP protocols
2. Set the socket in a way that it allows address re-use
3. Bind the socket to an address
4. Set the socket to listen to incoming connections
5. Once the socket accepts a connection, assess the ConnectionSocket and its address info. Check if it complies with a simplified [method, path, version, headers] protocol
6. ConnectionSocket parses the request then responds by either serving:
* A file (foo.txt)
* An executed script (foo.rb)
* + The apporpriate information (version, status code, status text, content-length, content)


### Trying it out

Serve a file
```
sh server_lite.sh 'http://127.0.0.1:9000/foo.txt'
```

Execute a file
```
sh server_lite.sh 'http://127.0.0.1:9000/foo.rb'
```


### Credits

[destroyallsoftware.com](https://www.destroyallsoftware.com/)