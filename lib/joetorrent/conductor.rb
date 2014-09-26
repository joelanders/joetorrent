require 'joetorrent'
require 'socket'
require 'pry'

class Conductor
  attr_accessor :metainfo, :tracker
  def initialize(filename)
    @metainfo = Metainfo.from_file filename
    @tracker = @metainfo.tracker
    Thread.abort_on_exception = true
  end

  def announce
    tracker.announce
  end

  def start_server
    server = TCPServer.new 6881
    loop do
      Thread.start(server.accept) do |client|
        puts 'got someone'
        ip = client.connect_address.ip_address
        port = client.connect_address.ip_port
        p = Peer.new ip, port, metainfo
        p.socket = client
        p.receive_and_send_handshake
        p.socket.write Message.bitfield((0...metainfo.num_pieces).to_a,
                                        metainfo.num_pieces)
        p.start_event_loop
        binding.pry
      end
    end
  end

  def start_client
    p = Peer.new '127.0.0.1', 6881, metainfo
    p.connect_socket
    p.send_and_receive_handshake
    p.socket.write Message.bitfield([], metainfo.num_pieces)
    p.start_event_loop
    binding.pry
  end

end
