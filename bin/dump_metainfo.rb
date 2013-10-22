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
mi.tracker.peers.each do |peer|
#pr = Peer.new '127.0.0.1', 51413
#[pr].each do |peer|
  puts peer.ip
  puts peer.port
  begin
    h = Handshake.new( peer.ip, peer.port, mi.info_hash, Tracker::PEER_ID )
    p h.shake
  rescue
    puts "ERROR " + $!.to_s
  end
end
binding.pry
