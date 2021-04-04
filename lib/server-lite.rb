#!/usr/bin/env ruby

require 'socket'

# A. Create a Server that listens to connections
def main
    # 0. A socket allows communication between two nodes over a network (whether local or external) using Unix file descriptors
    # => A file descriptor is just an integer associated with an open file and it can be a network connection, a text file, a terminal, or something else.
    # => A Unix Socket is used in a client-server application framework. A server is a process that performs some functions on request from a client. 
    # => Here, we choose IPv4 (:INET) and TCP (:STREAM) as our protocols
    socket = Socket.new(:INET, :STREAM)

    # 1. Set a socket option 
    #    x. Sets a socket option. These are protocol and system specific, see your local system documentation for details.
    #    x. https://www.gnu.org/software/libc/manual/html_node/Socket_002dLevel-Options.html#Socket_002dLevel-Options
    #    a. set the socket at the socket level (not a TCP option)
    #    b. re-use address: kill the server, immediately restart it, and avoid the kernel complain at us that we're using it already
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)

    # 2. Bind the address to the socket
    socket.bind(Addrinfo.tcp("127.0.0.1", 9000))

    # 3. Tell the socket to listen to connnections
    # => the arugment here is the number of backlog connections
    socket.listen(0)

    # 4. Accepts a request, then returns the address and socket
    # => Two sockets are now here (the main one and the socket returned from acceptin a connection)
    # => if you only leave 1-3 above then comment out the code below, then it's non-blocking. Step 4 is when the process starts to block
    # => by returning multiple sockets, this allows you to accept more connections and you'd be able to keep track of the data being passed around
    conn_sock, addr_info = socket.accept

    # 5. Have a way to read connections

    # 5.1. Allow your server to receive bytes
    # can accept up to 4096 bytes
    # there is no guarantee that the entire message is 4906 bytes
    # note that this also doesn't do anything
    # conn_sock.recv(4096)

    # 5.2. Allow something to read the connection
    # => This normally contains:
    # > GET /foo.txt HTTP/1.1
    # > Host: 127.0.0.1:9000
    # > User-Agent: curl/7.64.1
    # > Accept: */*

    conn = Connection.new(conn_sock)

    # 6. Returns a request object that has read through what the client asked for
    # Example: Object(GET, /foo.txt, {"Host"=>"127.0.0.1:9000", "User-Agent"=>"curl/7.64.1", "Accept"=>"*/*"})
    request = read_request(conn)

    # 7. Respond to the client for the given GET request
    respond_to_request(conn_sock, request)
end

# The Connection class:
# => can read one line through read_line
class Connection 
    def initialize(conn_sock)
        @conn_sock = conn_sock
        @buffer = ""
    end

    def read_line
        # carriage return + line feed (CRLF)
        # typewriter analogy
        # \r moves something to the left like a typewriter
        # \n moves something down
        read_until("\r\n")
    end

    def read_until(string)
        until @buffer.include?(string)
            @buffer += @conn_sock.recv(7)
        end
        result, @buffer = @buffer.split(string, 2)
        result
    end
end

def read_request(conn)
    # Read one line at a time
    request_line = conn.read_line

    # Based on the RFC standards, it's always split by a space
    # like this: [GET, /foo.txt, HTTP/1.1]
    method, path, version = request_line.split(" ", 3)
    
    # Create a header
    # like this: {"Host"=>"127.0.0.1:9000", "User-Agent"=>"curl/7.64.1", "Accept"=>"*/*"}
    headers = create_headers(conn)

    # Create a request with
    # GET, /foo.txt, {"Host"=>"127.0.0.1:9000", "User-Agent"=>"curl/7.64.1", "Accept"=>"*/*"}
    Request.new(method, path, headers)
end

# A Struct is a convenient way to bundle a number of attributes together, using accessor methods, without having to write an explicit class.
# => The Struct class generates new subclasses that hold a set of members and their values. 
Request = Struct.new(:method, :path, :headers)

def create_headers(conn)
    headers = {}
    loop do
        # based on the RFC standards, the header always uses ":"
        line = conn.read_line
        break if line.empty?

        key, value = line.split(/:\s*/, 2)
        headers[key] = value
    end
    return headers
end

def respond_to_request(conn_sock, request)
    # the below is very insecure code
    # example: ../../../etc/passwd => how exploits happened before
    path = Dir.getwd + request.path

    if File.exists?(path)
        # Returns true if the named file is executable by the effective user and group id of this process. See eaccess(3).
        if File.executable?(path)
            # How CGI bin & webapps work
            # https://en.wikipedia.org/wiki/Common_Gateway_Interface
            # Serves dynamic scripts

            # Returns the standard output of running cmd in a subshell. The built-in syntax %x{...} uses this method. Sets $? to the process status.
            content = `#{path}`
        else
            content = File.read(path)
        end

        status_code = 200
    else
        content = ""
        status_code = 404
    end

    # respond using determined status code & content
    respond(conn_sock, status_code, content)
end

def respond(conn_sock, status_code, content)
    status_text = {
        200 => "OK",
        404 => "NOT FOUND"
    }.fetch(status_code)

    # .send replies to the client; 0 == no flags
    conn_sock.send("HTTP/1.1 #{status_code} #{status_text}\r\n", 0)
    conn_sock.send("Content-Length: #{content.length}\r\n",0)
    conn_sock.send("\r\n", 0)
    conn_sock.send(content, 0)
end

main