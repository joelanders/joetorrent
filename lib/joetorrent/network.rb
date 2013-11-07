# recvfrom() man page says it will read the entire message from
# a SOCK_DGRAM in a single operation.
class UdpRequest
  def self.send msg, host, port, buf_size=65535
    # some rough checks because Errno::EINVAL is cryptic
    raise "bad msg: #{msg}" unless msg.is_a? String
    raise "bad host: #{host}" unless host.is_a?(String) &&
                                     host.match(/(?:\d{1,3}\.){3}\d{1,3}/)
    raise "bad port: #{port}" unless port.is_a?(Integer)
    u = UDPSocket.new
    u.bind('', 6882) # number not import. todo: if bind fails, switch port
    u.connect host, port
    u.send msg, 0 # zero is some flags we don't need
    response = u.recvfrom buf_size # ruby's default is 64k
    u.close
    response.first # todo: ensure resp. comes from expected IP
  end
end

class NatPMP
  GATEWAY = '192.168.1.1'
  GWYPORT = 5351
  def self.determine_external_address
    res = UdpRequest.send( NatPMPMessage.extip, GATEWAY, GWYPORT, 16 )
    raise "bad response #{res}" unless res.length == 12
    NatPMPMessage.from_packet res
  end

  def self.request_mapping inport, protocol
    raise "protocol (#{protocol}) must be :udp or :tcp" unless
      [:udp, :tcp].include? protocol

    res = UdpRequest.send( NatPMPMessage.request_mapping(inport, protocol),
                           GATEWAY, GWYPORT, 20 )
    raise "bad response #{res}" unless res.length == 16
    NatPMPMessage.from_packet res
  end
end

# all version 0
class NatPMPMessage
  # version 0, op 0
  def self.extip
    [0].pack('C') + [0].pack('C')
  end

  def self.request_mapping inport, protocol
    op = (protocol == :udp) ? "\x1" : "\x2"
    msg = ""
    msg += [0].pack('C') # version
    msg += op
    msg += [0].pack('S>') # reserved
    msg += [inport].pack('S>')
    msg += [0].pack('S>') # suggested external port
    msg += [7200].pack('L>') # sug. lifetime in seconds

    raise "bad msg #{msg}" unless msg.length == 12
    msg
  end

  def self.from_packet( packet )
    hash = {}
    hash[:version] = packet[0].unpack('C').first
    hash[:opcode] = packet[1].unpack('C').first
    hash[:result] = packet[2..3].unpack('S>').first
    hash[:time] = packet[4..7].unpack('L>').first # time since boot

    rest = case hash[:opcode]
           when 128 then from_extip( packet )
           when 129..130 then from_req_map( packet )
           else raise "unhandled opcode #{hash[:opcode]}"
           end

    hash.merge rest
  end

  private

  def self.from_extip( packet )
    hash = {}
    hash[:extip] = packet[8..11].unpack('CCCC').join('.')
    hash
  end

  def self.from_req_map( packet )
    hash = {}
    hash[:inport] = packet[8..9].unpack('S>').first
    hash[:export] = packet[10..11].unpack('S>').first
    hash[:maplife] = packet[12..15].unpack('L>').first
    hash
  end
end

