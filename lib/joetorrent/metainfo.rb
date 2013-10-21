require 'digest/sha1'

class Metainfo
  attr_accessor :hash, :tracker
  def self.from_file filename
    Metainfo.new File.open(filename, 'rb') {|f| f.read}
  end

  def initialize(bytes)
    @hash = Hash.from_bencoding bytes
    @tracker = Tracker.new self
  end

  def to_bencoding
    @hash.to_bencoding
  end

  def info_hash_hex
    info_hash.bytes_in_hex
  end

  def byte_length
    if @hash['info']['length']   # single file
      @hash['info']['length']
    elsif @hash['info']['files'] # multiple files
      @hash['info']['files'].inject(0) do |total, file|
        total + file['length']
      end
    end
  end

  def pieces
    @hash['info']['pieces']
  end

  def num_pieces
    pieces.length / 20
  end

  def pieces_hex
    arr = []
    (0...num_pieces).each do |i|
      arr << pieces.slice(20*i, 20)
    end
    arr.map {|p| p.bytes_in_hex}
  end

  def info_hash
    Digest::SHA1.digest(@hash['info'].to_bencoding)
  end

  def tracker_uri
    @hash['announce']
  end
end

class String
  def bytes_in_hex
    self.bytes.map{|b| sprintf "%02x", b}.join('')
  end
end
