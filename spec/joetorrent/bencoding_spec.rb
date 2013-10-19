require 'spec_helper'

describe Bencoder do
  describe ".get_next" do
    it "returns leading string and the remainder" do
      Bencoder.get_next('4:abcdi10e').should eq ['abcd', 'i10e']
    end
    it "returns a leading integer" do
      Bencoder.get_next('i10e2:ab1:a').should eq [10, '2:ab1:a']
    end
    it "returns :end when it hits a list or dict end marker" do
      Bencoder.get_next('eee').should eq [:end, 'ee']
    end

    it "handles an empty list" do
      Bencoder.get_next('lei2e').should eq [[], 'i2e']
    end
    it "handles a list containing a string" do
      Bencoder.get_next('l2:abe').should eq [['ab'], '']
    end
    it "handles a list with more elements" do
      Bencoder.get_next('li10e2:abe').should eq [[10, 'ab'], '']
    end

    it "handles a list within a list" do
      Bencoder.get_next('llee').should eq [[[]], '']
    end
    it "handles a more complicated nested list" do
      Bencoder.get_next('li2eli3eei4ee').
        should eq [[2, [3], 4], '']
    end

    it "handles an empty dictionary" do
      Bencoder.get_next('dei2e').should eq [{}, 'i2e']
    end
    it "handles a simple dictionary" do
      Bencoder.get_next('d1:ai1ee3:abc').should eq [{'a' => 1}, '3:abc']
    end
    it "raises an error on an invalid dictionary" do
      expect{Bencoder.get_next('d1:a1:b1:ce')}.to raise_error
    end
    it "handles nested dict" do
      Bencoder.get_next('dd1:ai1eed1:bi2eee4:abcd').
        should eq [{{'a' => 1} => {'b' => 2}}, '4:abcd']
    end
  end
end

describe String do
  describe "from_bencoding" do
    it "instantiates from a simple bencode" do
      String.from_bencoding('10:abcdefghij').should eq 'abcdefghij'
    end
  end

  describe "to_bencoding" do
    it "creates a simple bencode" do
      'bittorrent'.to_bencoding.to_s.should eq '10:bittorrent'
    end
  end
end

describe Integer do
  describe "from bencoding" do
    it "instantiates from a simple bencode" do
      Integer.from_bencoding('i64e').should eq 64
    end
    it "handles zero correctly" do
      Integer.from_bencoding('i0e').should eq 0
    end
    it "handles negatives correctly" do
      Integer.from_bencoding('i-10e').should eq -10
    end
  end

  describe "to_bencoding" do
    it "creates a simple bencode" do
      2048.to_bencoding.to_s.should eq 'i2048e'
    end
    it "handles zero correctly" do
      0.to_bencoding.to_s.should eq 'i0e'
    end
    it "handles negatives correctly" do
      -1.to_bencoding.to_s.should eq 'i-1e'
    end
  end
end

describe Array do
  describe "from bencoding" do
    it "instantiates from a single-element list" do
      Array.from_bencoding('l4:abcde').should eq ['abcd']
    end
  end

  describe "to_bencoding" do
    it "empty list" do
      [].to_bencoding.to_s.should eq 'le'
    end
    it "list with strings and ints" do
      [1, 'one', 2, 'two'].to_bencoding.to_s.
        should eq 'li1e3:onei2e3:twoe'
    end
    it "list within a list" do
      [1, [2], 3].to_bencoding.to_s.should eq 'li1eli2eei3ee'
    end
  end
end

describe Hash do
  describe "from_bencoding" do
    it "instantiates a simple hash" do
      Hash.from_bencoding('d1:a1:be').should eq( {'a' => 'b'} )
    end
  end

  describe "to_bencoding" do
    it "empty hash" do
      {}.to_bencoding.to_s.should eq 'de'
    end
    it "simple hash" do
      {'a' => 1}.to_bencoding.to_s.should eq 'd1:ai1ee'
    end
    it "hash in a hash" do
      {'a' => {'b' => 2}}.to_bencoding.to_s.should eq 'd1:ad1:bi2eee'
    end
  end
end
