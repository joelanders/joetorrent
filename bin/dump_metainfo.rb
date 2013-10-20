#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib',__FILE__)
require 'joetorrent'

mi = Metainfo.from_file ARGV[0]
p mi
