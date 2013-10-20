require 'net/http'

class Tracker
  attr_accessor :last_response
  def initialize metainfo
    @metainfo = metainfo
    @last_response = nil
  end

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
