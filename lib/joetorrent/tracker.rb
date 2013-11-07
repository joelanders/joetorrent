require 'net/http'
require 'socket'
require 'resolv'

class Tracker
  PEER_ID = '0123456789testing123'
  attr_accessor :last_response, :metainfo, :peers
  def initialize metainfo
    @metainfo = metainfo
    @tracker_con = UdpTrackerRequest.new(self)
    @peers = []
  end

  def tracker_uri
    URI(@metainfo.tracker_uri)
  end

  def announce
    res = @last_response = @tracker_con.announce
    @last_updated = Time.now
    @interval, @leechers, @seeders = res[8..-1].unpack('L>L>L>')
    num_peers = (res.length - 20)/6 # should be = to seeds + leeches
    (0...num_peers).each do |i|
      offset = (20 + 6*i)
      ip = res[offset...offset+4].bytes.to_a.join('.')
      port = res[offset..-1].unpack('S>').first
      @peers << Peer.new(ip, port, metainfo)
    end
    @peers
  end
end

# first we have to get a connection id, then we can do the announce
class UdpTrackerRequest
  CON_REQ_ID   = "\x00\x00\x04\x17\x27\x10\x19\x80"
  CON_REQ_ACT  = [0].pack('L>') # 0 in 32-bit unsigned big-endian
  ANN_ACT      = [1].pack('L>')
  ANN_EVT_NONE = [0].pack('L>')
  ANN_EVT_COMP = [1].pack('L>')
  ANN_EVT_STRT = [2].pack('L>')
  ANN_EVT_STOP = [3].pack('L>')
  def initialize(tracker)
    @tracker = tracker
    @uri = tracker.tracker_uri
    r = Resolv::DNS.open({:nameserver=>['208.67.222.222']}) #really?
    @ip = r.getaddress(@uri.host)
  end

  def announce
    get_connection_id
    get_announce_response
  end

  def get_connection_id
    res = @last_con_resp = UdpRequest.send con_req, @ip.to_s, @uri.port, 20
    @last_con_time = Time.now
    raise "expected 16 bytes: #{res}" unless res.length == 16
    rec_action = res[0...4]
    raise "action mismatch: #{rec_action}" unless rec_action == CON_REQ_ACT
    rec_trans = res[4...8]
    raise "trans. mismatch: #{rec_trans} " unless rec_trans == @last_trans_id
    @connection_id = res[8...16]
  end

  def get_announce_response
    raise 'no recent con. id' unless @connection_id &&
                                     Time.now - @last_con_time < 60
    res = @last_ann_resp = UdpRequest.send ann_req, @ip.to_s, @uri.port
    raise "should be >= 20 bytes #{res}" unless res.length >= 20
    raise "incomplete: #{res}" unless (res.length - 20)%6 == 0
    @last_ann_time = Time.now
    res
  end

  def random_transaction_id
    @last_trans_id = Random.new.bytes(4)
  end

  def con_req
    CON_REQ_ID + CON_REQ_ACT + random_transaction_id
  end

  def ann_req
    req = ""
    req += @connection_id
    req += ANN_ACT
    req += random_transaction_id
    req += @tracker.metainfo.info_hash
    req += Tracker::PEER_ID
    req += [0].pack('Q>') # downloaded, 64-bit unsigned big-endian
    req += [@tracker.metainfo.byte_length].pack('Q>') # left
    req += [0].pack('Q>') # uploaded
    req += ANN_EVT_STRT # lots of these vals should change later
    req += [0].pack('L>') # 32-bit IP (optional)
    req += [0].pack('L>') # 32-bit key (optional)
    req += [-1].pack('l>') # num_want, -1
    req += [6881].pack('S>') # 16-bit port

    raise "bad ann_req: #{req}" unless req.length == 98
    req
  end
end

class HttpTrackerRequest
  def announce
    params = { :info_hash  => @metainfo.info_hash,
               :peer_id    => Tracker::PEER_ID,
               :port       => 6881,
               :uploaded   => 0,
               :downloaded => 0,
               :left       => @metainfo.hash['info']['length'],
               :compact    => 0,
               :event      => 'started',
             }
    uri = URI(@metainfo.tracker_uri)
    uri.query = URI.encode_www_form params
    @last_response = Net::HTTP.get_response uri
  end
end
