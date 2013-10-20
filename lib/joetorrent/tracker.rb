require 'net/http'
require 'socket'
require 'resolv'

class Tracker
  PEER_ID = '0123456789testing123'
  attr_accessor :last_response, :metainfo
  def initialize metainfo
    @metainfo = metainfo
    @last_response = nil
    @tracker_con = UdpTrackerRequest.new(self)
  end

  def tracker_uri
    URI(@metainfo.tracker_uri)
  end

  def announce
    @last_response = @tracker_con.announce
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
    @last_transaction_id = nil
    @last_con_resp = nil
    @last_con_time = nil
    @last_ann_resp = nil
    @last_ann_time = nil
    @connection_id = nil
    r = Resolv::DNS.open({:nameserver=>['208.67.222.222']}) #really?
    @ip = r.getaddress(@uri.host)
  end

  def announce
    get_connection_id
    get_announce_response
  end

  def get_connection_id
    usock = UDPSocket.new
    usock.bind('', 6882)
    puts @ip.to_s
    puts @uri.port
    p con_req
    usock.connect @ip.to_s, @uri.port
    usock.send con_req, 0
    @last_con_time = Time.now
    @last_con_resp = usock.recvfrom(20,0).first
    usock.close
    rec_action = @last_con_resp[0...4]
    raise "action mismatch: #{rec_action}" unless rec_action == CON_REQ_ACT
    rec_transaction_id = @last_con_resp[4...8]
    raise "transaction id mismatch: #{rec_transaction_id} " unless
      rec_transaction_id == @last_transaction_id
    @connection_id = @last_con_resp[8...16]
  end

  def get_announce_response
    raise 'no recent con. id' unless @connection_id &&
                                     Time.now - @last_con_time < 60
    usock = UDPSocket.new
    usock.bind('', 6882)
    usock.connect @ip.to_s, @uri.port
    req = ann_req # this changes @last_transaction_id
    p req
    usock.send req, 0
    @last_ann_time = Time.now
    @last_ann_resp = usock.recvfrom(620,0).first # room for 100 peers
    usock.close
    puts "announce response: action, transaction, interval, leech, seed"
    p @last_ann_resp.unpack('L>L>L>L>L>') # five 32-bit values
    num_peers = (@last_ann_resp.length - 20) / 6
    puts "#{num_peers} peers"
    (0...num_peers).each do |i|
      puts "ip: " + @last_ann_resp[(20 + 6*i)..-1].unpack('L>').first.to_s
      puts "pt: " + @last_ann_resp[(24 + 6*i)..-1].unpack('S>').first.to_s
      puts
    end
    @last_ann_resp
  end

  def random_transaction_id
    @last_transaction_id = Random.new.bytes(4)
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
