#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib',__FILE__)
require 'joetorrent'
require 'pry'

mi = Metainfo.from_file 'boa.torrent'
mi.tracker.announce
pr = Peer.new '127.0.0.1', 51413, mi
pr.connect_socket
pr.do_handshake
pr.socket.write Message.bitfield([], mi.num_pieces)
pr.start_event_loop
pr.socket.write Message.request 0, 0, 2**4
binding.pry
