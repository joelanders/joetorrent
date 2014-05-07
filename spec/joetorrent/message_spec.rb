require 'spec_helper'

# todo: make Messages throw exceptions on invalid parameters.
describe Message do
  describe ".keep_alive" do
    it "is always the same message" do
      Message.keep_alive.should eq "\x00\x00\x00\x00"
    end
  end

  describe ".choke" do
    it "is always the same message" do
      Message.choke.should eq "\x00\x00\x00\x01\x00"
    end
  end

  describe ".unchoke" do
    it "is always the same message" do
      Message.unchoke.should eq "\x00\x00\x00\x01\x01"
    end
  end

  describe ".interested" do
    it "is always the same message" do
      Message.interested.should eq "\x00\x00\x00\x01\x02"
    end
  end

  describe ".not_interested" do
    it "is always the same message" do
      Message.not_interested.should eq "\x00\x00\x00\x01\x03"
    end
  end

  describe ".have" do
    it "encodes a 32-bit piece index" do
      Message.have(  0).should eq "\x00\x00\x00\x05\x04\x00\x00\x00\x00"
      Message.have(256).should eq "\x00\x00\x00\x05\x04\x00\x00\x01\x00"
    end
  end

  #todo: fix this horrible encoding crap
  describe ".bitfield" do
    it "single piece bitfield" do
      have_piece = ([2].pack('L>') + "\x05\x80").force_encoding("BINARY") 
      Message.bitfield( [0], 1 ).should eq(have_piece)
      dont_have_piece = ([2].pack('L>') + "\x05\x00").force_encoding("BINARY")
      Message.bitfield( [], 1 ).should eq(dont_have_piece)
    end
    it "single byte (8 pieces) bitfield" do
      expected = ([2].pack('L>') + "\x05\xb8").force_encoding("BINARY")
      Message.bitfield( [0, 3, 2, 4], 8 ).
        should eq(expected) # 0b10111000 = 0xb8
    end
    it "two byte (12 pieces) bitfield" do
      expected = ([3].pack('L>') + "\x05\x80\x20").force_encoding("BINARY")
      Message.bitfield( [0, 10], 12 ).
        should eq(expected) # 0b10111000 = 0xb8
    end
    it "12 byte (90 pieces) bitfield" do
      expected = ([13].pack('L>') + "\x05\x40\x01" + "\x00"*9 + "\xc0").force_encoding("BINARY")
      Message.bitfield( [1, 15, 88, 89], 90 ).
        should eq(expected)
    end
  end

  # identical to .cancel except for message id
  describe ".request" do
    it "encodes piece_index, offset, block_length" do
      Message.request( 257, 2**16, 2**14 ).
        should eq [13].pack('L>') + "\x06" +
                  [257].pack('L>') +
                  [2**16].pack('L>') +
                  [2**14].pack('L>')
    end
  end

  describe ".piece" do
    it "encodes piece_index, offset, and block_data" do
      Message.piece( 2, 0, "\xff\xfb\x90\x44" ).
        should eq [13].pack('L>') + "\x07" +
                  [2].pack('L>') +
                  [0].pack('L>') +
                  "\xff\xfb\x90\x44"
    end
  end

  # identical to .request except for message id
  describe ".cancel" do
    it "encodes piece_index, offset, block_length" do
      Message.cancel( 257, 2**16, 2**14 ).
        should eq [13].pack('L>') + "\x08" +
                  [257].pack('L>') +
                  [2**16].pack('L>') +
                  [2**14].pack('L>')
    end
  end
end
