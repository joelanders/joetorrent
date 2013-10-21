require 'socket'

class Peer
  attr_accessor :ip, :port
  attr_accessor :am_choking, :am_interested
  attr_accessor :peer_choking, :peer_interested
  def initialize ip, port
    @ip, @port = ip, port
    @am_choking = true
    @am_interested = false
    @peer_choking = true
    @peer_interested = false
  end

  def to_s
    'peer' + sprintf('%16s', ip) + ' ' + sprintf('%-5s', port.to_s)
  end
end

class Handshake
  def initialize ip, port, info_hash, peer_id
    @ip, @port = ip, port
    @info_hash, @peer_id = info_hash, peer_id
  end

  def shake
    s = Socket.new( Socket::AF_INET, Socket::SOCK_STREAM, 0 )
    s.connect Socket.pack_sockaddr_in( @port, @ip )
    s.write msg
    @reply = ''
    while @reply.length < 68
      @reply += s.getc
    end
    s.close
    @reply
  end

  def msg
    msg = ''
    msg += [19].pack 'C' # aka "\x13", length of next string
    msg += 'BitTorrent protocol' # do you speak it?!
    msg += [0].pack 'Q>' # 8 reserved bytes
    msg += @info_hash
    msg += @peer_id

    raise "bad msg #{msg}" unless msg.length == 68
    msg
  end
end
