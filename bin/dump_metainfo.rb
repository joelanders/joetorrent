#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib',__FILE__)
require 'joetorrent'
require 'digest/sha1'
require 'pry'

mi = Metainfo.from_file ARGV[0]
#p mi.hash
p mi.info_hash_hex
p mi.tracker_uri
#p mi.tracker.announce
#p Hash.from_bencoding mi.tracker.last_response.body.to_s
binding.pry
