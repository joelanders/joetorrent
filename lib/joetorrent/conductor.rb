require 'joetorrent'
require 'socket'
require 'pry'

class Conductor
  attr_accessor :metainfo, :tracker, :my_pieces
  attr_accessor :file, :file_pieces
  attr_accessor :piece_length, :num_pieces
  def initialize(filename)
    @metainfo = Metainfo.from_file filename
    @tracker = @metainfo.tracker
    @my_pieces = [] # indices of my pieces
    @file = nil # assembled file
    @file_pieces = [] # pieces of file
    @piece_length = metainfo.hash['info']['piece length']
    @num_pieces = metainfo.num_pieces
    Thread.abort_on_exception = true
  end

  def announce
    tracker.announce
  end

  def load_file_and_pieces
    @file = File.read( metainfo.hash['info']['name'] ).b
    @file_pieces = (0...num_pieces).map do |index|
      file[index * piece_length, piece_length]
    end
  end

  def start_server
    server = TCPServer.new 6881
    load_file_and_pieces
    my_pieces = (0..num_pieces).to_a
    raise 'bad length' if file.length != metainfo.hash['info']['length']
    loop do
      Thread.start(server.accept) do |client|
        puts 'got someone'
        ip = client.connect_address.ip_address
        port = client.connect_address.ip_port
        p = Peer.new ip, port, self
        p.socket = client
        p.receive_and_send_handshake
        p.socket.write Message.bitfield((0...metainfo.num_pieces).to_a,
                                        metainfo.num_pieces)
        p.start_event_loop
        p.socket.write Message.unchoke
        binding.pry
      end
    end
  end

  def start_client
    p = Peer.new '127.0.0.1', 6881, self
    p.connect_socket
    p.send_and_receive_handshake
    p.socket.write Message.bitfield([], metainfo.num_pieces)
    p.start_event_loop
    p.socket.write Message.interested
    (0...num_pieces).each do |index|
      p.socket.write Message.request index, 0, 2**16
    end
    loop do
      puts "have #{my_pieces.length} / 73"
      break if my_pieces.length == 73
      sleep 1
    end
    dled_piece_hashes = p.conductor.file_pieces.map do |piece|
      Digest::SHA1.new.update(piece).to_s
    end
    puts dled_piece_hashes == p.conductor.metainfo.pieces_hex
    binding.pry
  end

end
