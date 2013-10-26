require 'socket'

class Peer
  attr_accessor :ip, :port
  attr_accessor :metainfo
  attr_accessor :am_choking, :am_interested
  attr_accessor :peer_choking, :peer_interested
  attr_accessor :socket
  def initialize ip, port, metainfo
    @ip, @port = ip, port
    @metainfo = metainfo
    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false
  end

  # this blocks until it connects; raises if it times out
  def connect_socket timeout=1
    @socket = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, 0 )
    begin
      socket.connect_nonblock Socket.pack_sockaddr_in( @port, @ip )
    rescue IO::WaitWritable
      raise "connect timeout" unless IO.select [], [socket], [], timeout
    end
    @socket
  end

  def do_handshake
    @handshake_reply = Handshake.new(self).shake
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

    @reply = ''.force_encoding Encoding::BINARY
    while IO.select([peer.socket], [], [], 5) && @reply.length < 68
      char = peer.socket.read 1
      break if char.nil? # EOF; we got dropped
      @reply += char
    end
    @reply
  end

  def msg
    msg = ''
    msg += [19].pack 'C' # aka "\x13", length of next string
    msg += 'BitTorrent protocol' # do you speak it?!
    msg += [0].pack 'Q>' # 8 reserved bytes
    msg += peer.metainfo.info_hash
    msg += Tracker::PEER_ID

    raise "bad msg #{msg}" unless msg.length == 68
    msg
  end
end
