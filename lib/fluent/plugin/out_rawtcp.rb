#
# Fluent
#
# Copyright (C) 2011 FURUHASHI Sadayuki
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
module Fluent
  class RawTcpOutput < Fluent::BufferedOutput
    Plugin.register_output('rawtcp', self)

    def initialize
      super
      require 'socket'
      require 'timeout'
      require 'fileutils'
      @nodes = []  #=> [Node]
    end

    config_param :send_timeout, :time, :default => 60
    config_param :recover_wait, :time, :default => 10
    config_param :hard_timeout, :time, :default => 60
    attr_reader :nodes

    def configure(conf)
      super

      conf.elements.each {|e|
        next if e.name != "server"

        host = e['host']
        port = e['port']
        port = port ? port.to_i : DEFAULT_LISTEN_PORT

        name = e['name']
        unless name
          name = "#{host}:#{port}"
        end

        node_conf = RawNodeConfig.new(name, host, port)
        @nodes << Node.new(log, node_conf)
        log.info "adding forwarding server '#{name}'", :host=>host, :port=>port
      }
    end

    def start
      super
    end

    def shutdown
      super
    end

    def write(chunk)
      return if chunk.empty?

      error = nil

      @nodes.each do |node|
        begin
          send_data(node, chunk)
          return
        rescue
          error = $!
        end
      end

      raise error if error
      raise "No nodes available"
    end

    private
    def send_data(node, chunk)
      sock = connect(node)
      begin
        opt = [1, @send_timeout.to_i].pack('I!I!')  # { int l_onoff; int l_linger; }
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, opt)

        opt = [@send_timeout.to_i, 0].pack('L!L!')  # struct timeval
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, opt)

        chunk.msgpack_each do |tag, time, record|
          next unless record.is_a? Hash
          sock.write([tag, time, record].to_msgpack)
        end
      ensure
        sock.close
      end
    end

    def connect(node)
      Timeout.timeout(5) do
        return TCPSocket.new(node.resolved_host, node.port)
      end
    end

    RawNodeConfig = Struct.new("RawNodeConfig", :name, :host, :port)

    class Node
      def initialize(log, conf)
        @log = log
        @conf = conf
        @name = @conf.name
        @host = @conf.host
        @port = @conf.port

        @resolved_host = nil
        @resolved_time = 0
        resolved_host  # check dns
      end

      attr_reader :conf
      attr_reader :name, :host, :port
      attr_accessor :failure, :available

      def available?
        @available
      end

      def standby?
        @conf.standby
      end

      def resolved_host
        @sockaddr = Socket.pack_sockaddr_in(@port, @host)
        port, rhost = Socket.unpack_sockaddr_in(@sockaddr)
        return rhost
      end
    end
  end
end
