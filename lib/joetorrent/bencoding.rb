# Weird responsibility-sharing between Bencoder and the from_bencoding
# instance methods. Sort that out later. Also error-checking.

class Bencoder
  def self.get_next(str)
    case str[0]
    when /\d/
      colon_index = str.index(':')
      str_len = str[0...colon_index].to_i
      last_char_index = str_len + colon_index
      [String.from_bencoding(str[0..last_char_index]),
       str[last_char_index+1..-1]]
    when 'i'
      last_char = str.index('e')
      [Integer.from_bencoding(str[0..last_char]),
       str[last_char+1..-1]]
    when 'l'
      list = []
      start = 1
      val, rem = Bencoder.get_next str[1..-1]
      while val != :end
        list << val
        val, rem = Bencoder.get_next rem
      end
      [list, rem]
    when 'd'
      kvs = []
      start = 1
      val, rem = Bencoder.get_next str[1..-1]
      while val != :end
        kvs << val
        val, rem = Bencoder.get_next rem
      end
      raise 'bad dict' if kvs.length.odd?
      dict = {}
      kvs.each_with_index {|kv, i| i.even? ? dict[kv] = kvs[i+1] : nil}
      [dict, rem]
    when 'e'
      [:end, str[1..-1]]
    else
      raise "bencoding error #{str[0]}"
    end
  end
end

# example: "spam" <-> "4:spam"
class String
  def self.from_bencoding(benstr)
    colon_index = benstr.index ':'
    len = benstr[0...colon_index]
    str = benstr[colon_index+1..-1]
    str
  end
  def to_bencoding
    length.to_s + ':' + to_s
  end
end

# example: 64 <-> "i64e"
class Integer
  def self.from_bencoding(benstr)
    benstr[1..-2].to_i
  end
  def to_bencoding
    'i' + to_s + 'e'
  end
end

# example: ['ab', 7] <-> "l2:abi7ee"
class Array
  def self.from_bencoding(benstr)
    Bencoder.get_next(benstr)[0]
  end
  def to_bencoding
    'l' + map(&:to_bencoding).join('') + 'e'
  end
end

# example: {'a' => 'b'} <-> "d1:a1:be"
class Hash
  def self.from_bencoding(benstr)
    Bencoder.get_next(benstr)[0]
  end
  def to_bencoding
    'd' + flatten.map(&:to_bencoding).join('') + 'e'
  end
end
