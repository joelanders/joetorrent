#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib',__FILE__)
require 'joetorrent'
require 'pry'
Pry.config.print = proc { |output, value| output.puts "=> #{value.to_s}" }

#mi = Metainfo.from_file 'boa.torrent'
#mi.tracker.announce
#pr = Peer.new '127.0.0.1', 51413, mi
#pr.connect_socket
#pr.do_handshake
##pr.socket.write Message.bitfield([], mi.num_pieces)
#pr.socket.write Message.bitfield((1..mi.num_pieces).to_a, mi.num_pieces)
#pr.start_event_loop
#pr.socket.write Message.unchoke
##pr.socket.write Message.request 0, 0, 2**4

c = Conductor.new 'boa.torrent'
binding.pry
