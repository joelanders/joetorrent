require 'net/http'
require 'socket'
require 'resolv'

class Tracker
  attr_accessor :last_response
  def initialize metainfo
    @metainfo = metainfo
    @last_response = nil
  end

  def announce
    @last_response = UdpTrackerRequest.
      new( URI(@metainfo.tracker_uri) ).
      send
  end
end

class UdpTrackerRequest
  CON_REQ_ID  = "\x00\x00\x04\x17\x27\x10\x19\x80"
  CON_REQ_ACT = "\x00\x00\x00\x00"
  def initialize(uri)
    @uri = uri
    @last_con_resp = nil
    r = Resolv::DNS.open({:nameserver=>['208.67.222.222']}) #really?
    @ip = r.getaddress(@uri.host)
  end

  def send
    usock = UDPSocket.new
    usock.bind('', 6882)
    puts @ip.to_s
    puts @uri.port
    p con_req
    usock.connect @ip.to_s, @uri.port
    usock.send con_req, 0
    @last_con_resp = usock.recvfrom(20,0)
  end

  def con_req
    CON_REQ_ID + CON_REQ_ACT + Random.new.bytes(4)
  end
end

class HttpTrackerRequest
  def announce
    params = { :info_hash  => @metainfo.info_hash,
               :peer_id    => '0123456789testing123',
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
