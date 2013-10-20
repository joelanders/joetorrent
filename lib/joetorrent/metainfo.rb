class Metainfo
  attr_accessor :hash
  def self.from_file filename
    bytes = File.read(filename).force_encoding Encoding::ASCII #hack...
    @hash = Hash.from_bencoding bytes
  end
end
