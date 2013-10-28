#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib',__FILE__)
require 'joetorrent'
require 'digest/sha1'
require 'pry'

mi = Metainfo.from_file ARGV[0]
#p mi.hash
p mi.info_hash_hex
p mi.tracker_uri
mi.tracker.announce
#p Hash.from_bencoding mi.tracker.last_response.body.to_s
#pr = Peer.new '127.0.0.1', 51413, mi
#[pr].each do |peer|

threads = []
goodps = []
badps = []

mi.tracker.peers.each do |peer|
  threads << Thread.new do
    begin
      peer.connect_socket 10
      peer.do_handshake
      goodps << peer
    rescue
      badps << peer
      peer.socket.close
    end
  end
end

#pr.connect_socket
#pr.do_handshake
#pr.socket.write Message.bitfield([], mi.num_pieces)
#pr.start_event_loop

binding.pry
