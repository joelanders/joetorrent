require 'digest/sha1'

class Metainfo
  attr_accessor :hash, :tracker
  def self.from_file filename
    Metainfo.new File.read(filename).force_encoding Encoding::ASCII #hack...
  end

  def initialize(bytes)
    @hash = Hash.from_bencoding bytes
    @tracker = Tracker.new self
  end

  def to_bencoding
    @hash.to_bencoding
  end

  # i have no patience for the docs today
  def info_hash_hex
    info_hash.bytes.to_a.map {|b| b.to_s 16}.join ''
  end

  def info_hash
    Digest::SHA1.digest(@hash['info'].to_bencoding)
  end

  def tracker_uri
    @hash['announce']
  end
end
