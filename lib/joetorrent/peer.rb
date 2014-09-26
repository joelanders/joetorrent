require 'socket'

class Peer
  attr_accessor :ip, :port
  attr_accessor :inport, :export
  attr_accessor :metainfo
  attr_accessor :am_choking, :am_interested
  attr_accessor :peer_choking, :peer_interested
  attr_accessor :socket
  attr_accessor :recd_messages
  attr_accessor :pieces
  attr_accessor :to_rate, :from_rate # "upload" and "download"
  attr_accessor :thread
  attr_accessor :conductor
  def initialize ip, port, conductor
    @ip, @port = ip, port
    @conductor = conductor
    @metainfo = conductor.metainfo
    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false
    @recd_messages = []
    @peer_pieces = []
  end

  # this blocks until it connects; raises if it times out
  def connect_socket timeout=10
    @socket = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, 0 )

    socket.bind( Socket.pack_sockaddr_in( 0, '' ) )
    @inport = socket.local_address.ip_port

    #@export = NatPMP.request_mapping( inport, :tcp )[:export]

    #puts self.to_s + " #{inport} #{export}"

    begin
      socket.connect_nonblock Socket.pack_sockaddr_in( @port, @ip )
    rescue IO::WaitWritable
      unless IO.select [], [socket], [], timeout
        socket.close
        raise "connect timeout"
      end
    end
    @socket
  end

  def send_and_receive_handshake
    h = Handshake.new(self)
    h.shake
    @handshake_reply = h.receive_shake
    raise "got no shake after we shook" if @handshake_reply.nil?
    recd_messages << {:time => Time.now, :handshake => @handshake_reply}
  end

  def receive_and_send_handshake
    h = Handshake.new(self)
    @handshake_reply = h.receive_shake
    raise "got no shake" if @handshake_reply.nil?
    h.shake
    recd_messages << {:time => Time.now, :handshake => @handshake_reply}
  end

  def start_event_loop
    @thread = Thread.new do
      loop do
        IO.select [socket], [], []
        length = socket.read_with_timeout(4, 5).unpack('L>').first
        if length.nil?
          # handle EOF
          raise 'eof'
        else # we have an actual message
          handle_message length
        end
      end
    end
  end

  # TODO: raise proper exceptions
  def handle_message length
    if length == 0
      socket.write Message.keep_alive
      return :keep_alive
    end

    msg_code = socket.read_with_timeout(1, 5).unpack('C').first
    raise "got no message code" if msg_code.nil?

    case msg_code
    when 0
      decoded = :choke
      raise "bad :choke length: #{length}" unless length == 1
    when 1
      decoded = :unchoke
      raise "bad :unchoke length: #{length}" unless length == 1
    when 2
      decoded = :interested
      raise "bad :interested length: #{length}" unless length == 1
    when 3
      decoded = :uninterested
      raise "bad :uninterested length: #{length}" unless length == 1
    when 4
      piece = socket.read_with_timeout(4, 5).unpack('L>').first
      raise "failed to receive :have message" if piece.nil?
      decoded = {:have => piece}
    when 5
      bitfield = socket.read_with_timeout(length - 1, 5)
      raise "failed to receive bitfield message" if bitfield.nil?
      pieces = Message.bitfield_to_indices(bitfield, metainfo.num_pieces)
      decoded = {:pieces => pieces}
    when 6
      raise "request message has length #{length}" unless length == 13
      message = socket.read_with_timeout(length - 1, 5)
      raise "failed to receive request message" if message.nil?
      piece, start, length = Message.decomp_request message
      decoded = {:request => piece, :start => start, :length => length}
      socket.write Message.piece(piece,
                                 start,
                                 @conductor.file_pieces[piece][start, length])
    when 7
      # they're sending a piece of a piece (we'll call it a "block")
      # first read piece index and start offset
      piece, start = socket.read_with_timeout(8, 5).unpack('L>L>')
      block = socket.read_with_timeout(length - 9, 5)
      decoded = {:piece => piece, :start => start, :length => block.length}
      # geto hack only works if block length = piece length
      @conductor.file_pieces[piece] = block
      @conductor.my_pieces << piece
    when 8
      decoded = :cancel
    when 9
      decoded = :some_dht_thing
    else
      decoded = :unhandled
    end

    recd_messages << {:time => Time.now, :decoded => decoded}
  end

  def stop_event_loop
    Thread.kill @thread
  end

  def to_s
    'peer' + sprintf('%16s', ip) + ' ' + sprintf('%-5s', port.to_s)
  end
end

class Handshake
  attr_accessor :reply
  attr_accessor :peer
  def initialize peer
    @peer = peer
  end

  def shake
    raise "socket is nil" unless peer.socket
    raise "socket not writable" unless IO.select [], [peer.socket], [], 0

    peer.socket.write msg
  end

  # TODO: callers need to handle a possible nil response
  def receive_shake
    # 68-byte handshake
    peer.socket.read_with_timeout 68, 5
  end

  def msg
    msg = ''.b
    msg += [19].pack 'C' # aka "\x13", length of next string
    msg += 'BitTorrent protocol' # do you speak it?!
    msg += [0].pack 'Q>' # 8 reserved bytes
    msg += peer.metainfo.info_hash
    msg += Tracker::PEER_ID

    raise "bad msg #{msg}" unless msg.length == 68
    msg
  end
end
