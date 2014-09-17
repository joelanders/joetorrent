class Message
  def self.keep_alive
    [0].pack('L>')
  end

  def self.choke
    [1, 0].pack('L>C')
  end

  def self.unchoke
    [1, 1].pack('L>C')
  end

  def self.interested
    [1, 2].pack('L>C')
  end

  def self.not_interested
    [1, 3].pack('L>C')
  end

  def self.have piece_index
    [5, 4, piece_index].pack('L>CL>')
  end

  # num_pieces is total number of pieces in the torrent
  # nasty as hell; find a better way sometime.
  def self.bitfield piece_indices, num_pieces
    bigint = 0
    piece_indices.each do |piece_index|
      bigint |= (1<<piece_index)
    end

    num_bytes = (num_pieces.to_f / 8).ceil
    bitfield = ""

    num_bytes.times do
      byte = bigint % (1<<8)
      rev_byte = 0
      8.times do # reverse bit-order in the byte...
        rev_byte = rev_byte << 1
        rev_byte += byte % 2
        byte = byte >> 1
      end
      bitfield += [rev_byte].pack 'C'
      bigint = bigint >> 8
    end

    [1+bitfield.length, 5].pack('L>C') + bitfield
  end

  # bitfield argument is actually a string
  def self.bitfield_to_indices bitfield, num_pieces
    raise "bitfield not even number of bytes" unless bitfield.length % 8 == 0
    raise "num_pieces > bitfield.length" if num_pieces > bitfield.length
    indices = []
    (0..num_pieces).each do |index|
      indices << index if bitfield[index] == "1"
    end
    indices
  end

  # offset is the starting position of the requested block
  # within the piece.
  def self.request piece_index, offset, block_length
    [13].pack('L>') + "\x06" +
      [piece_index].pack('L>') +
      [offset].pack('L>') +
      [block_length].pack('L>')
  end

  def self.decomp_request msg
    raise "bad message #{msg}" unless msg.length == 12
    # index, offset, length
    msg.unpack('L>L>L>')
  end

  # not a metainfo "piece," this is actually a "block"
  def self.piece piece_index, offset, block_data
    [9+block_data.length].pack('L>') + "\x07" +
      [piece_index].pack('L>') +
      [offset].pack('L>') +
      block_data
  end

  def self.cancel piece_index, offset, block_length
    [13].pack('L>') + "\x08" +
      [piece_index].pack('L>') +
      [offset].pack('L>') +
      [block_length].pack('L>')
  end

  # for DHT
  def self.port number
    [3].pack('L>') + "\x09" + [number].pack('S>')
  end
end
