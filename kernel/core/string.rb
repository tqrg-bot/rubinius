# depends on: comparable.rb enumerable.rb
  
# Default Ruby Record Separator
# Used in this file and by various methods that need to ignore $/
DEFAULT_RECORD_SEPARATOR = "\n"

class String
  include Comparable
  include Enumerable
  
  ivar_as_index :bytes => 0, :characters => 1, :encoding => 2, :data => 3, :hash => 4, :shared => 5
  def bytes     ; @bytes      ; end
  def characters; @characters ; end
  def encoding  ; @encoding   ; end
  def data      ; @data       ; end
  def __ivars__ ; nil         ; end

  # Can't be changed if run inside instance_eval with no param passed in
  def initialize(arg = nil)
    if Fixnum === arg
      arg ||= ""
      # + 1 for the null on the end.
      @data = ByteArray.new(arg+1)
      @bytes = arg
      @characters = arg
      @encoding = nil
    elsif !@bytes || arg
      replace(arg || "")
    end
    self
  end
  # private :initialize

  # call-seq:
  #   str % arg   => new_str
  #  
  # Format---Uses <i>self</i> as a format specification, and returns the result
  # of applying it to <i>arg</i>. If the format specification contains more than
  # one substitution, then <i>arg</i> must be an <code>Array</code> containing
  # the values to be substituted. See <code>Kernel::sprintf</code> for details
  # of the format string.
  # 
  #   "%05d" % 123                       #=> "00123"
  #   "%-5s: %08x" % [ "ID", self.id ]   #=> "ID   : 200e14d6"
  def %(args)
    YSprintf.new(self, *args).parse
    # Sprintf::Parser.format(self, args)
  end

  # call-seq:
  #   str * integer   => new_str
  #
  # Copy --- Returns a new <code>String</code> containing <i>integer</i> copies of
  # the receiver.
  #   
  #   "Ho! " * 3   #=> "Ho! Ho! Ho! "
  def *(num)
    unless num.is_a? Integer
      raise "Can't convert #{num.class} to Integer" unless num.respond_to? :to_int
      num = num.to_int
    end
    
    raise RangeError, "bignum too big to convert into `long'" if num.is_a? Bignum
    raise ArgumentError, "unable to multiple negative times (#{num})" if num < 0

    str = []
    num.times { str << self }
    str = self.class.new(str.join)
    str.taint if self.tainted?
    return str
  end
  
  # Concatenation --- Returns a new <code>String</code> containing
  # <i>other</i> concatenated to <i>string</i>.
  # 
  #   "Hello from " + self.to_s   #=> "Hello from main"
  def +(other)
    r = String.new(self) << other
    r.taint if self.tainted? || other.tainted?
    r
  end

  # Append --- Concatenates the given object to <i>self</i>. If the object is a
  # <code>Fixnum</code> between 0 and 255, it is converted to a character before
  # concatenation.
  #    
  #   a = "hello "
  #   a << "world"   #=> "hello world"
  #   a.concat(33)   #=> "hello world!"
  def <<(other)
    unless other.kind_of? String
      if other.is_a?(Integer) && other >= 0 && other <= 255
        other = other.chr
      else
        other = StringValue(other)
      end
    end
    
    self.modify!
    self.taint if other.tainted?
    self.append(other)
  end
  alias_method :concat, :<<

  # call-seq:
  #   str <=> other_str   => -1, 0, +1
  # 
  # Comparison --- Returns -1 if <i>other_str</i> is less than, 0 if
  # <i>other_str</i> is equal to, and +1 if <i>other_str</i> is greater than
  # <i>self</i>. If the strings are of different lengths, and the strings are
  # equal when compared up to the shortest length, then the longer string is
  # considered greater than the shorter one. If the variable <code>$=</code> is
  # <code>false</code>, the comparison is based on comparing the binary values
  # of each character in the string. In older versions of Ruby, setting
  # <code>$=</code> allowed case-insensitive comparisons; this is now deprecated
  # in favor of using <code>String#casecmp</code>.
  #
  # <code><=></code> is the basis for the methods <code><</code>,
  # <code><=</code>, <code>></code>, <code>>=</code>, and <code>between?</code>,
  # included from module <code>Comparable</code>. The method
  # <code>String#==</code> does not use <code>Comparable#==</code>.
  #    
  #    "abcdef" <=> "abcde"     #=> 1
  #    "abcdef" <=> "abcdef"    #=> 0
  #    "abcdef" <=> "abcdefg"   #=> -1
  #    "abcdef" <=> "ABCDEF"    #=> 1
  def <=>(other)
    if String === other
      len = other.size
      len = size if size < len

      od = other.data
      len.times do |i|
        result = (@data.get_byte(i) <=> od.get_byte(i))
        return result if result != 0
      end

      if size < other.size
        return -1
      elsif size > other.size
        return 1
      else
        return 0
      end
    else
      return unless other.respond_to?(:to_str) && other.respond_to?(:<=>)
      return unless tmp = (other <=> self)
      return -tmp # We're not supposed to convert to integer here
    end
  end

  # call-seq:
  #    str == obj   => true or false
  # 
  # Equality---If <i>obj</i> is not a <code>String</code>, returns
  # <code>false</code>. Otherwise, returns <code>true</code> if <i>self</i>
  # <code><=></code> <i>obj</i> returns zero.
  #---
  # TODO: MRI does simply use <=> for Strings here, so what's this code about?
  #+++ 
  def ==(other)
    if String === other
      return false unless @bytes == other.size
      
      # This clamps the data to the right size, then we compare
      # FIXME: This is very inefficient, creating a new ByteArray just
      # to compare. 
      ld = @data.fetch_bytes(0, @bytes)
      rd = other.data.fetch_bytes(0, @bytes)
      
      return (ld <=> rd) == 0
      
      # It would be nice if the rest of this worked, but it had problems
      # last I (evan) tried. We need to go through and make sure null termination
      # of ByteArray's is universal.
      od = other.data
      if @data.size == od.size
        return (@data <=> od) == 0
      elsif @data.size < od.size
        puts "od is bigger"
        return (od.fetch_bytes(0, @data.size) <=> @data) == 0
      else
        puts "data is bigger"
        out = (@data.fetch_bytes(0, od.size) <=> od)
        p out
        return out == 0
      end
    elsif other.respond_to?(:to_str)
      return other == self
    end
    false
  end
  alias_method :===, :==

  # Match --- If <i>pattern</i> is a <code>Regexp</code>, use it as a pattern to match
  # against <i>self</i>, and return the position the match starts, or 
  # <code>nil</code> if there is no match. Otherwise, invoke
  # <i>pattern.=~</i>, passing <i>self</i> as an argument.
  # 
  # The default <code>=~</code> in <code>Object</code> returns <code>false</code>.
  #    
  #   "cat o' 9 tails" =~ /\d/ #=> 7
  #   "cat o' 9 tails" =~ 9    #=> false
  def =~(pattern)
    case pattern
    when Regexp
      pattern.match(self)
    when String
      raise TypeError, "type mismatch: String given"
    else
      pattern =~ self
    end
  end

  # call-seq:
  #    str[fixnum]                 => fixnum or nil
  #    str[fixnum, fixnum]         => new_str or nil
  #    str[range]                  => new_str or nil
  #    str[regexp]                 => new_str or nil
  #    str[regexp, fixnum]         => new_str or nil
  #    str[other_str]              => new_str or nil
  #    str.slice(fixnum)           => fixnum or nil
  #    str.slice(fixnum, fixnum)   => new_str or nil
  #    str.slice(range)            => new_str or nil
  #    str.slice(regexp)           => new_str or nil
  #    str.slice(regexp, fixnum)   => new_str or nil
  #    str.slice(other_str)        => new_str or nil
  # 
  # Element Reference --- If passed a single <code>Fixnum</code>, returns the code
  # of the character at that position. If passed two <code>Fixnum</code>
  # objects, returns a substring starting at the offset given by the first, and
  # a length given by the second. If given a range, a substring containing
  # characters at offsets given by the range is returned. In all three cases, if
  # an offset is negative, it is counted from the end of <i>self</i>. Returns
  # <code>nil</code> if the initial offset falls outside the string, the length
  # is negative, or the beginning of the range is greater than the end.
  #    
  # If a <code>Regexp</code> is supplied, the matching portion of <i>self</i> is
  # returned. If a numeric parameter follows the regular expression, that
  # component of the <code>MatchData</code> is returned instead. If a
  # <code>String</code> is given, that string is returned if it occurs in
  # <i>self</i>. In both cases, <code>nil</code> is returned if there is no
  # match.
  #    
  #    a = "hello there"
  #    a[1]                   #=> 101
  #    a[1,3]                 #=> "ell"
  #    a[1..3]                #=> "ell"
  #    a[-3,2]                #=> "er"
  #    a[-4..-2]              #=> "her"
  #    a[12..-1]              #=> nil
  #    a[-2..-4]              #=> ""
  #    a[/[aeiou](.)\1/]      #=> "ell"
  #    a[/[aeiou](.)\1/, 0]   #=> "ell"
  #    a[/[aeiou](.)\1/, 1]   #=> "l"
  #    a[/[aeiou](.)\1/, 2]   #=> nil
  #    a["lo"]                #=> "lo"
  #    a["bye"]               #=> nil
  def [](index, other = Undefined)
    if other != Undefined
      length = Type.coerce_to(other, Fixnum, :to_int)
      
      if index.kind_of? Regexp
        return subpattern(index, length)
      else
        start  = Type.coerce_to(index, Fixnum, :to_int)
        return substring(start, length)
      end
    end
    
    case index
    when Regexp
      return subpattern(index, 0)
    when String
      return include?(index) ? index.dup : nil
    when Range
      start   = Type.coerce_to index.first, Fixnum, :to_int
      length  = Type.coerce_to index.last,  Fixnum, :to_int

      start += @bytes if start < 0

      length += @bytes if length < 0
      length += 1 unless index.exclude_end?
      
      return "" if start == @bytes
      return nil if start < 0 || start > @bytes
      
      length = @bytes if length > @bytes
      length = length - start
      length = 0 if length < 0
      
      return substring(start, length)
    else
      index = Type.coerce_to index, Fixnum, :to_int
      index = @bytes + index if index < 0
    
      return if index < 0 || @bytes <= index
      return @data[index]      
    end
  end
  alias_method :slice, :[]

  # call-seq:
  #   str[fixnum] = fixnum
  #   str[fixnum] = new_str
  #   str[fixnum, fixnum] = new_str
  #   str[range] = aString
  #   str[regexp] = new_str
  #   str[regexp, fixnum] = new_str
  #   str[other_str] = new_str
  # 
  # Element Assignment --- Replaces some or all of the content of <i>self</i>. The
  # portion of the string affected is determined using the same criteria as
  # <code>String#[]</code>. If the replacement string is not the same length as
  # the text it is replacing, the string will be adjusted accordingly. If the
  # regular expression or string is used as the index doesn't match a position
  # in the string, <code>IndexError</code> is raised. If the regular expression
  # form is used, the optional second <code>Fixnum</code> allows you to specify
  # which portion of the match to replace (effectively using the
  # <code>MatchData</code> indexing rules. The forms that take a
  # <code>Fixnum</code> will raise an <code>IndexError</code> if the value is
  # out of range; the <code>Range</code> form will raise a
  # <code>RangeError</code>, and the <code>Regexp</code> and <code>String</code>
  # forms will silently ignore the assignment.
  def []=(*args)
    if args.size == 3
      if args.first.is_a? Regexp
        self.subpattern_set(args[0], Type.coerce_to(args[1], Integer, :to_int), args[2])
      else
        self.splice(Type.coerce_to(args[0], Integer, :to_int), Type.coerce_to(args[1], Integer, :to_int), args[2])
      end
      
      return args.last
    elsif args.size != 2
      raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
    end
    
    index = args[0]
    replacement = args[1]
    
    case index
    when Regexp
      self.subpattern_set(index, 0, replacement)
    when String
      unless start = self.index(index)
        raise IndexError, "string not matched"
      end
      
      self.splice(start, index.length, replacement)
    when Range
      start   = Type.coerce_to(index.first, Integer, :to_int)
      length  = Type.coerce_to(index.last, Integer, :to_int)

      start += @bytes if start < 0
      
      # TODO: this is wrong
      return nil if start < 0 || start > @bytes

      length = @bytes if length > @bytes
      length += @bytes if length < 0
      length += 1 unless index.exclude_end?
      
      length = length - start
      length = 0 if length < 0
      
      self.splice(start, length, replacement)
    else
      index = Type.coerce_to(index, Integer, :to_int)
      raise IndexError, "index #{index} out of string" if @bytes <= index
      
      if index < 0
        raise IndexError, "index #{index} out of string" if -index > @bytes
        index += @bytes
      end
      
      if replacement.is_a?(Fixnum)
        self.modify!
        @data[index] = replacement
      else
        self.splice(index, 1, replacement)
      end
    end
    return replacement
  end

  # Returns a copy of <i>self</i> with the first character converted to uppercase
  # and the remainder to lowercase.
  # Note: case conversion is effective only in ASCII region.
  #    
  #   "hello".capitalize    #=> "Hello"
  #   "HELLO".capitalize    #=> "Hello"
  #   "123ABC".capitalize   #=> "123abc"
  def capitalize
    (str = self.dup).capitalize! || str
  end

  # Modifies <i>self</i> by converting the first character to uppercase and the
  # remainder to lowercase. Returns <code>nil</code> if no changes are made.
  # Note: case conversion is effective only in ASCII region.
  #    
  #   a = "hello"
  #   a.capitalize!   #=> "Hello"
  #   a               #=> "Hello"
  #   a.capitalize!   #=> nil
  def capitalize!
    self.modify!
    return if @bytes == 0
    
    modified = false
    
    if @data[0].islower
      @data[0] = @data[0].toupper
      modified = true
    end
    
    1.upto(@bytes - 1) do |i|
      if @data[i].isupper
        @data[i] = @data[i].tolower
        modified = true
      end
    end
  
    modified ? self : nil
  end

  # Case-insensitive version of <code>String#<=></code>.
  #    
  #   "abcdef".casecmp("abcde")     #=> 1
  #   "aBcDeF".casecmp("abcdef")    #=> 0
  #   "abcdef".casecmp("abcdefg")   #=> -1
  #   "abcdef".casecmp("ABCDEF")    #=> 0
  def casecmp(to)
    self.upcase <=> to.upcase
  end

  # If <i>integer</i> is greater than the length of <i>self</i>, returns a new
  # <code>String</code> of length <i>integer</i> with <i>self</i> centered and
  # padded with <i>padstr</i>; otherwise, returns <i>self</i>.
  #    
  #    "hello".center(4)         #=> "hello"
  #    "hello".center(20)        #=> "       hello        "
  #    "hello".center(20, '123') #=> "1231231hello12312312"
  def center(integer, padstr = " ")
    justify(integer, :center, padstr)
  end

  # Returns a new <code>String</code> with the given record separator removed
  # from the end of <i>self</i> (if present). If <code>$/</code> has not been
  # changed from the default Ruby record separator, then <code>chomp</code> also
  # removes carriage return characters (that is it will remove <code>\n</code>,
  # <code>\r</code>, and <code>\r\n</code>).
  #    
  #   "hello".chomp            #=> "hello"
  #   "hello\n".chomp          #=> "hello"
  #   "hello\r\n".chomp        #=> "hello"
  #   "hello\n\r".chomp        #=> "hello\n"
  #   "hello\r".chomp          #=> "hello"
  #   "hello \n there".chomp   #=> "hello \n there"
  #   "hello".chomp("llo")     #=> "he"
  def chomp(separator = $/)
    (str = self.dup).chomp!(separator) || str
  end
  
  # Modifies <i>self</i> in place as described for <code>String#chomp</code>,
  # returning <i>self</i>, or <code>nil</code> if no modifications were made.
  #---
  # NOTE: TypeError is raised in String#replace and not in String#chomp! when
  # self is frozen. This is intended behaviour.
  #+++
  def chomp!(separator = $/)
    return nil if separator.nil? || @bytes == 0

    if separator == $/ && separator == DEFAULT_RECORD_SEPARATOR
      return smart_chomp!
    end
    
    separator = StringValue(separator)
    length = @bytes - 1
    
    if separator.length == 0 
      while length > 0 && @data[length] == ?\n
        length -= 1
        length -= 1 if length > 0 && @data[length] == ?\r
      end
      
      return replace(substring(0, length + 1)) if length + 1 < @bytes
      return nil
    elsif separator.length > @bytes
      return nil
    elsif separator.length == 1 && separator == "\n"
      return self.smart_chomp!
    elsif @data[length].chr == separator || self[-separator.length, separator.length] == separator
      return replace(substring(0, length + 1 - separator.length))
    end
  end
  
  # Returns a new <code>String</code> with the last character removed.  If the
  # string ends with <code>\r\n</code>, both characters are removed. Applying
  # <code>chop</code> to an empty string returns an empty
  # string. <code>String#chomp</code> is often a safer alternative, as it leaves
  # the string unchanged if it doesn't end in a record separator.
  #    
  #   "string\r\n".chop   #=> "string"
  #   "string\n\r".chop   #=> "string\n"
  #   "string\n".chop     #=> "string"
  #   "string".chop       #=> "strin"
  #   "x".chop.chop       #=> ""
  def chop
    (str = self.dup).chop! || str
  end

  # Processes <i>self</i> as for <code>String#chop</code>, returning <i>self</i>,
  # or <code>nil</code> if <i>self</i> is the empty string.  See also
  # <code>String#chomp!</code>.
  def chop!
    return if @bytes == 0
    
    length = @bytes - 1
    length -= 1 if @data[length] == ?\n && @data[length - 1] == ?\r
    
    replace(substring(0, length))
  end
  
  # Each <i>other_string</i> parameter defines a set of characters to count.  The
  # intersection of these sets defines the characters to count in
  # <i>self</i>. Any <i>other_str</i> that starts with a caret (^) is
  # negated. The sequence c1--c2 means all characters between c1 and c2.
  #    
  #   a = "hello world"
  #   a.count "lo"            #=> 5
  #   a.count "lo", "o"       #=> 2
  #   a.count "hello", "^l"   #=> 4
  #   a.count "ej-m"          #=> 4
  def count(*strings)
    raise ArgumentError, "wrong number of Arguments" if strings.empty?
    return 0 if @bytes == 0
    
    pattern = tr_regex(strings)
    count = start = 0
    
    while start < @bytes and match = pattern.match_from(self, start)
      start = match.begin(0) + 1
      count += 1
    end
    
    count
  end
  
  # Applies a one-way cryptographic hash to <i>self</i> by invoking the standard
  # library function <code>crypt</code>. The argument is the salt string, which
  # should be two characters long, each character drawn from
  # <code>[a-zA-Z0-9./]</code>.
  def crypt(other_str)
    other_str = StringValue(other_str)
    raise ArgumentError.new("salt must be at least 2 characters") if other_str.size < 2

    hash = __crypt__(other_str)
    hash.taint if self.tainted? || other_str.tainted?
    hash
  end

  # Returns a copy of <i>self</i> with all characters in the intersection of its
  # arguments deleted. Uses the same rules for building the set of characters as
  # <code>String#count</code>.
  #    
  #   "hello".delete "l","lo"        #=> "heo"
  #   "hello".delete "lo"            #=> "he"
  #   "hello".delete "aeiou", "^e"   #=> "hell"
  #   "hello".delete "ej-m"          #=> "ho"
  def delete(*strings)
    (str = self.dup).delete!(*strings) || str
  end

  # Performs a <code>delete</code> operation in place, returning <i>self</i>, or
  # <code>nil</code> if <i>self</i> was not modified.
  def delete!(*strings)
    raise ArgumentError, "wrong number of arguments" if strings.empty?
    new = []
    
    last_end = 0
    last_match = nil
    pattern = tr_regex(strings)
    
    while match = pattern.match_from(self, last_end)
      new << match.pre_match_from(last_end) 
      last_end = match.begin(0) + 1
    end
    
    new << self[last_end..-1] if self[last_end..-1]
    new = new.join
    new != self ? replace(new) : nil
  end
  
  # Returns a copy of <i>self</i> with all uppercase letters replaced with their
  # lowercase counterparts. The operation is locale insensitive---only
  # characters ``A'' to ``Z'' are affected.
  # 
  # "hEllO".downcase   #=> "hello"
  def downcase
    (str = self.dup).downcase! || str
  end
  
  # Downcases the contents of <i>self</i>, returning <code>nil</code> if no
  # changes were made.
  def downcase!
    return if @bytes == 0
    self.modify!
  
    modified = false
  
    @bytes.times do |i|
      if @data[i].isupper
        @data[i] = @data[i].tolower
        modified = true
      end
    end

    modified ? self : nil
  end
  
  # Passes each byte in <i>self</i> to the given block.
  #    
  #   "hello".each_byte {|c| print c, ' ' }
  #    
  # <em>produces:</em>
  #    
  #   104 101 108 108 111
  def each_byte()
    i = 0
    while i < @bytes do
      yield @data.get_byte(i)
      i += 1
    end
    self
  end

  # works exactly like each_byte, but returns characters instead of bytes
  def each_char()
    i = 0
    while i < @bytes do
      yield @data.get_byte(i).chr
      i += 1
    end
    self
  end

  # Splits <i>self</i> using the supplied parameter as the record separator
  # (<code>$/</code> by default), passing each substring in turn to the supplied
  # block. If a zero-length record separator is supplied, the string is split on
  # <code>\n</code> characters, except that multiple successive newlines are
  # appended together.
  #    
  #   print "Example one\n"
  #   "hello\nworld".each {|s| p s}
  #   print "Example two\n"
  #   "hello\nworld".each('l') {|s| p s}
  #   print "Example three\n"
  #   "hello\n\n\nworld".each('') {|s| p s}
  #    
  # <em>produces:</em>
  #    
  #   Example one
  #   "hello\n"
  #   "world"
  #   Example two
  #   "hel"
  #   "l"
  #   "o\nworl"
  #   "d"
  #   Example three
  #   "hello\n\n\n"
  #   "world"
  def each(separator = $/)
    if separator.nil?
      yield self
      return self
    end

    separator = StringValue(separator)
    
    raise LocalJumpError, "no block given" unless block_given?
    
    newline = separator.empty? ? ?\n : separator[separator.length - 1]
    
    last_index = 0
    index = separator.length
    
    old_str = self.dup
    
    while index < self.length
      if separator.empty?
        index += 1 while (self.size > index + 2) && self[(index + 1)..(index + 2)] =~ /[^\n]/
        index += 1 while (self.size > index + 1) && self[index + 1] == ?\n
      end
    
      if self[index] == newline && self[-separator.length, separator.length]
        line = self[last_index..index]
        line.taint if self.tainted?
        yield line
        raise RuntimeError, "You modified the string while running each" if old_str != self
        last_index = index + 1
      end
      
      index += 1
    end
    
    unless last_index == self.length
      line = self[last_index..self.length]
      line.taint if self.tainted?
      yield line
    end

    self
  end
  alias_method :each_line, :each

  # Returns <code>true</code> if <i>self</i> has a length of zero.
  #    
  #   "hello".empty?   #=> false
  #   "".empty?        #=> true
  def empty?
    @bytes == 0
  end

  # Two strings are equal if the have the same length and content.
  def eql?(other)
    return false unless other.is_a?(String) && other.size == @bytes
    (@data.fetch_bytes(0, @bytes) <=> other.data.fetch_bytes(0, @bytes)) == 0
  end

  # Returns a copy of <i>self</i> with <em>all</em> occurrences of <i>pattern</i>
  # replaced with either <i>replacement</i> or the value of the block. The
  # <i>pattern</i> will typically be a <code>Regexp</code>; if it is a
  # <code>String</code> then no regular expression metacharacters will be
  # interpreted (that is <code>/\d/</code> will match a digit, but
  # <code>'\d'</code> will match a backslash followed by a 'd').
  #    
  # If a string is used as the replacement, special variables from the match
  # (such as <code>$&</code> and <code>$1</code>) cannot be substituted into it,
  # as substitution into the string occurs before the pattern match
  # starts. However, the sequences <code>\1</code>, <code>\2</code>, and so on
  # may be used to interpolate successive groups in the match.
  #    
  # In the block form, the current match string is passed in as a parameter, and
  # variables such as <code>$1</code>, <code>$2</code>, <code>$`</code>,
  # <code>$&</code>, and <code>$'</code> will be set appropriately. The value
  # returned by the block will be substituted for the match on each call.
  #    
  # The result inherits any tainting in the original string or any supplied
  # replacement string.
  #    
  #   "hello".gsub(/[aeiou]/, '*')              #=> "h*ll*"
  #   "hello".gsub(/([aeiou])/, '<\1>')         #=> "h<e>ll<o>"
  #   "hello".gsub(/./) {|s| s[0].to_s + ' '}   #=> "104 101 108 108 111 "
  def gsub(pattern, replacement = nil, &block)
    str_gsub(pattern, replacement, false, &block)
  end
  
  # Performs the substitutions of <code>String#gsub</code> in place, returning
  # <i>self</i>, or <code>nil</code> if no substitutions were performed.
  def gsub!(pattern, replacement = nil, &block)
    str_gsub(pattern, replacement, true, &block)
  end

  # Treats leading characters from <i>self</i> as a string of hexadecimal digits
  # (with an optional sign and an optional <code>0x</code>) and returns the
  # corresponding number. Zero is returned on error.
  #    
  #    "0x0a".hex     #=> 10
  #    "-1234".hex    #=> -4660
  #    "0".hex        #=> 0
  #    "wombat".hex   #=> 0
  def hex
    self.to_inum(16)
  end

  # Returns <code>true</code> if <i>self</i> contains the given string or
  # character.
  #    
  #   "hello".include? "lo"   #=> true
  #   "hello".include? "ol"   #=> false
  #   "hello".include? ?h     #=> true
  def include?(needle)
    if needle.is_a? Fixnum
      each_byte { |b| return true if b == (needle % 256) }
      return false
    end

    !self.index(StringValue(needle)).nil?
  end

  # Returns the index of the first occurrence of the given <i>substring</i>,
  # character (<i>fixnum</i>), or pattern (<i>regexp</i>) in <i>self</i>. Returns
  # <code>nil</code> if not found. If the second parameter is present, it
  # specifies the position in the string to begin the search.
  # 
  #   "hello".index('e')             #=> 1
  #   "hello".index('lo')            #=> 3
  #   "hello".index('a')             #=> nil
  #   "hello".index(101)             #=> 1
  #   "hello".index(/[aeiou]/, -3)   #=> 4
  def index(needle, offset = 0)
    offset = Type.coerce_to(offset, Integer, :to_int)
    offset = @bytes + offset if offset < 0
    return nil if offset < 0 || offset > @bytes

    needle = needle.to_str if !needle.instance_of?(String) && needle.respond_to?(:to_str)

    # What are we searching for?
    case needle
    when Fixnum
      (offset...self.size).each do |i|
        return i if @data[i] == needle
      end
    when String
      return offset if needle == ""
            
      needle_size = needle.size
      
      max = @bytes - needle_size
      return if max < 0 # <= 0 maybe?
      
      offset.upto(max) do |i|
        if @data[i] == needle.data[0]
          return i if substring(i, needle_size) == needle
        end
      end
    when Regexp
      if match = needle.match(self[offset..-1])
        return (offset + match.begin(0))
      end
    else
      raise TypeError, "type mismatch: #{needle.class} given"
    end

    return nil
  end
  
  # Inserts <i>other_string</i> before the character at the given
  # <i>index</i>, modifying <i>self</i>. Negative indices count from the
  # end of the string, and insert <em>after</em> the given character.
  # The intent is insert <i>other_string</i> so that it starts at the given
  # <i>index</i>.
  #    
  #   "abcd".insert(0, 'X')    #=> "Xabcd"
  #   "abcd".insert(3, 'X')    #=> "abcXd"
  #   "abcd".insert(4, 'X')    #=> "abcdX"
  #   "abcd".insert(-3, 'X')   #=> "abXcd"
  #   "abcd".insert(-1, 'X')   #=> "abcdX"
  def insert(index, other_string)
    other_string = StringValue(other_string)
    
    index = Integer(index)
    
    if index == -1
      return self << other_string
    elsif index < 0
      index += 1
    end
    
    self[index, 0] = other_string
    self
  end

  ControlCharacters = [?\n, ?\t, ?\a, ?\v, ?\f, ?\r, ?\e, ?\b]
  ControlPrintValue = ["\\n", "\\t", "\\a", "\\v", "\\f", "\\r", "\\e", "\\b"]

  # Returns a printable version of _self_, with special characters
  # escaped.
  #
  #   str = "hello"
  #   str[3] = 8
  #   str.inspect       #=> "hel\010o"
  def inspect
    return "\"#{self}\"".copy_properties(self) if $KCODE == "UTF-8"
    res =  "\""
    self.each_byte do |char|
      if ci = ControlCharacters.index(char)
        res << ControlPrintValue[ci]
      elsif char == ?"
        res << "\\\""
      elsif char == ?\\
        res << "\\\\"
      elsif char == ?#
        res << "\\\#"
      elsif char < 32 or char > 126
        v = char.to_s(8)
        if v.size == 1
          res << "\\00#{v}"
        elsif v.size == 2
          res << "\\0#{v}"
        else
          res << "\\#{v}"
        end
      else
        res << char.chr
      end
    end
    res << "\""
    return res.copy_properties(self)
  end

  # Returns the length of <i>self</i>.
  def length
    @bytes
  end
  alias_method :size, :length

  # If <i>integer</i> is greater than the length of <i>self</i>, returns a new
  # <code>String</code> of length <i>integer</i> with <i>self</i> left justified
  # and padded with <i>padstr</i>; otherwise, returns <i>self</i>.
  #    
  #   "hello".ljust(4)            #=> "hello"
  #   "hello".ljust(20)           #=> "hello               "
  #   "hello".ljust(20, '1234')   #=> "hello123412341234123"
  def ljust(integer, padstr = " ")
    justify(integer, :left, padstr)
  end
  
  # Returns a copy of <i>self</i> with leading whitespace removed. See also
  # <code>String#rstrip</code> and <code>String#strip</code>.
  #    
  #   "  hello  ".lstrip   #=> "hello  "
  #   "hello".lstrip       #=> "hello"
  def lstrip
    (str = self.dup).lstrip! || str
  end
  
  # Removes leading whitespace from <i>self</i>, returning <code>nil</code> if no
  # change was made. See also <code>String#rstrip!</code> and
  # <code>String#strip!</code>.
  #    
  #   "  hello  ".lstrip   #=> "hello  "
  #   "hello".lstrip!      #=> nil
  def lstrip!
    return if @bytes == 0
  
    start = 0
    while start < @bytes
      c = @data[start]
      if c.isspace
        start += 1
      else
        break
      end
    end
  
    return if start == 0
    replace(substring(start, @bytes - start))
  end

  # Converts <i>pattern</i> to a <code>Regexp</code> (if it isn't already one),
  # then invokes its <code>match</code> method on <i>self</i>.
  #    
  #   'hello'.match('(.)\1')      #=> #<MatchData:0x401b3d30>
  #   'hello'.match('(.)\1')[0]   #=> "ll"
  #   'hello'.match(/(.)\1/)[0]   #=> "ll"
  #   'hello'.match('xx')         #=> nil
  def match(pattern)
    get_pattern(pattern).match(self)
  end

  # Treats leading characters of <i>self</i> as a string of octal digits (with an
  # optional sign) and returns the corresponding number. Returns 0 if the
  # conversion fails.
  #    
  #   "123".oct       #=> 83
  #   "-377".oct      #=> -255
  #   "bad".oct       #=> 0
  #   "0377bad".oct   #=> 255
  def oct
    self.to_inum(-8)
  end

  # Replaces the contents and taintedness of <i>string</i> with the corresponding
  # values in <i>other</i>.
  # 
  #   s = "hello"         #=> "hello"
  #   s.replace "world"   #=> "world"
  def replace(other)
    # If we're replacing with ourselves, then we have nothing to do
    return self if self.equal?(other)

    other = StringValue(other)

    @shared = true
    other.shared!
    @data = other.data
    @bytes = other.bytes
    @characters = other.characters
    @encoding = other.encoding
    
    self.taint if other.tainted?
    
    self
  end
  alias_method :initialize_copy, :replace
  # private :initialize_copy

  # Returns a new string with the characters from <i>self</i> in reverse order.
  #    
  #   "stressed".reverse   #=> "desserts"
  def reverse
    self.dup.reverse!
  end

  # Reverses <i>self</i> in place.
  def reverse!
    return self if @bytes <= 1
    self.modify!
    
    i = 0
    j = @bytes - 1
    while i < j
      a = @data[i]
      b = @data[j]
      @data[j] = a
      @data[i] = b
      i += 1
      j -= 1
    end
    self
  end

  # Returns the index of the last occurrence of the given <i>substring</i>,
  # character (<i>fixnum</i>), or pattern (<i>regexp</i>) in <i>self</i>. Returns
  # <code>nil</code> if not found. If the second parameter is present, it
  # specifies the position in the string to end the search---characters beyond
  # this point will not be considered.
  #    
  #   "hello".rindex('e')             #=> 1
  #   "hello".rindex('l')             #=> 3
  #   "hello".rindex('a')             #=> nil
  #   "hello".rindex(101)             #=> 1
  #   "hello".rindex(/[aeiou]/, -2)   #=> 1
  def rindex(arg, finish = Undefined)
    arg = StringValue(arg) unless [Fixnum, String, Regexp].include?(arg.class)
    original_klass = arg.class
    if finish != Undefined
      finish = Type.coerce_to(finish, Integer, :to_int)
      finish += @bytes if finish < 0
      return nil if finish < 0
      finish = @bytes if finish >= @bytes
    else
      finish = size
    end
    case arg
    when Fixnum
      return nil if arg > 255 || arg < 0
      arg = Regexp.new(Regexp.quote(arg.chr))
    when String
      arg = Regexp.new(Regexp.quote(arg))
    end
    
    ret = arg.match_region(self, 0, finish, false)
    $~ = ret if original_klass == Regexp
    ret && ret.begin(0)
  end

  # If <i>integer</i> is greater than the length of <i>self</i>, returns a new
  # <code>String</code> of length <i>integer</i> with <i>self</i> right justified
  # and padded with <i>padstr</i>; otherwise, returns <i>self</i>.
  #    
  #   "hello".rjust(4)            #=> "hello"
  #   "hello".rjust(20)           #=> "               hello"
  #   "hello".rjust(20, '1234')   #=> "123412341234123hello"
  def rjust(integer, padstr = " ")
    justify(integer, :right, padstr)
  end
  
  # Returns a copy of <i>self</i> with trailing whitespace removed. See also
  # <code>String#lstrip</code> and <code>String#strip</code>.
  #    
  #   "  hello  ".rstrip   #=> "  hello"
  #   "hello".rstrip       #=> "hello"
  def rstrip
    (str = self.dup).rstrip! || str
  end

  # Removes trailing whitespace from <i>self</i>, returning <code>nil</code> if
  # no change was made. See also <code>String#lstrip!</code> and
  # <code>String#strip!</code>.
  # 
  #   "  hello  ".rstrip   #=> "  hello"
  #   "hello".rstrip!      #=> nil
  def rstrip!
    return if @bytes == 0
    
    stop = @bytes - 1
    while stop >= 0
      c = @data[stop]
      if c.isspace || c == 0
        stop -= 1
      else
        break
      end
    end

    return if stop + 1 == @bytes
    replace(substring(0, stop + 1))
  end


  # Both forms iterate through <i>self</i>, matching the pattern (which may be a
  # <code>Regexp</code> or a <code>String</code>). For each match, a result is
  # generated and either added to the result array or passed to the block. If
  # the pattern contains no groups, each individual result consists of the
  # matched string, <code>$&</code>.  If the pattern contains groups, each
  # individual result is itself an array containing one entry per group.
  #    
  #   a = "cruel world"
  #   a.scan(/\w+/)        #=> ["cruel", "world"]
  #   a.scan(/.../)        #=> ["cru", "el ", "wor"]
  #   a.scan(/(...)/)      #=> [["cru"], ["el "], ["wor"]]
  #   a.scan(/(..)(..)/)   #=> [["cr", "ue"], ["l ", "wo"]]
  #    
  # And the block form:
  #    
  #   a.scan(/\w+/) {|w| print "<<#{w}>> " }
  #   print "\n"
  #   a.scan(/(.)(.)/) {|x,y| print y, x }
  #   print "\n"
  #    
  # <em>produces:</em>
  #    
  #   <<cruel>> <<world>>
  #   rceu lowlr
  def scan(pattern, &block)
    taint = self.tainted? || pattern.tainted?
    pattern = get_pattern(pattern, true)
    index = 0

    unless block_given?
      ret = []
      while (index, match = scan_once(pattern, index)) && match
        last_match = $~
        match.taint if taint
        ret << match
      end
      
      $~ = last_match
      return ret
    else
      while (index, match = scan_once(pattern, index)) && match
        last_match = old_md = $~
        
        match.taint if taint
        
        block.call(match)
        $~ = old_md
      end
      
      $~ = last_match
      return self
    end
  end
  
  # Deletes the specified portion from <i>self</i>, and returns the portion
  # deleted. The forms that take a <code>Fixnum</code> will raise an
  # <code>IndexError</code> if the value is out of range; the <code>Range</code>
  # form will raise a <code>RangeError</code>, and the <code>Regexp</code> and
  # <code>String</code> forms will silently ignore the assignment.
  #    
  #   string = "this is a string"
  #   string.slice!(2)        #=> 105
  #   string.slice!(3..6)     #=> " is "
  #   string.slice!(/s.*t/)   #=> "sa st"
  #   string.slice!("r")      #=> "r"
  #   string                  #=> "thing"
  def slice!(*args)
    result = slice(*args)
    self[*args] = '' unless result.nil?
    result
  end

  # Divides <i>self</i> into substrings based on a delimiter, returning an array
  # of these substrings.
  #    
  # If <i>pattern</i> is a <code>String</code>, then its contents are used as
  # the delimiter when splitting <i>self</i>. If <i>pattern</i> is a single
  # space, <i>self</i> is split on whitespace, with leading whitespace and runs
  # of contiguous whitespace characters ignored.
  #    
  # If <i>pattern</i> is a <code>Regexp</code>, <i>self</i> is divided where the
  # pattern matches. Whenever the pattern matches a zero-length string,
  # <i>self</i> is split into individual characters.
  #    
  # If <i>pattern</i> is omitted, the value of <code>$;</code> is used.  If
  # <code>$;</code> is <code>nil</code> (which is the default), <i>self</i> is
  # split on whitespace as if ` ' were specified.
  #    
  # If the <i>limit</i> parameter is omitted, trailing null fields are
  # suppressed. If <i>limit</i> is a positive number, at most that number of
  # fields will be returned (if <i>limit</i> is <code>1</code>, the entire
  # string is returned as the only entry in an array). If negative, there is no
  # limit to the number of fields returned, and trailing null fields are not
  # suppressed.
  #    
  #   " now's  the time".split        #=> ["now's", "the", "time"]
  #   " now's  the time".split(' ')   #=> ["now's", "the", "time"]
  #   " now's  the time".split(/ /)   #=> ["", "now's", "", "the", "time"]
  #   "1, 2.34,56, 7".split(%r{,\s*}) #=> ["1", "2.34", "56", "7"]
  #   "hello".split(//)               #=> ["h", "e", "l", "l", "o"]
  #   "hello".split(//, 3)            #=> ["h", "e", "llo"]
  #   "hi mom".split(%r{\s*})         #=> ["h", "i", "m", "o", "m"]
  #    
  #   "mellow yellow".split("ello")   #=> ["m", "w y", "w"]
  #   "1,2,,3,4,,".split(',')         #=> ["1", "2", "", "3", "4"]
  #   "1,2,,3,4,,".split(',', 4)      #=> ["1", "2", "", "3,4,,"]
  #   "1,2,,3,4,,".split(',', -4)     #=> ["1", "2", "", "3", "4", "", ""]
  def split(pattern = nil, limit = nil)
    limit = limit.to_int if (!limit.is_a?(Integer) && limit.respond_to?(:to_int))
    return [self.dup] if limit == 1
    limited = limit.to_i > 1
    pattern ||= ($; || " ")
    
    spaces = true if pattern == ' '
    pattern = /\s+/ if pattern == nil || pattern == ' '
    pattern = pattern.to_str if ![String, Regexp].include?(pattern.class) && pattern.respond_to?(:to_str)
    pattern = Regexp.new(Regexp.quote(pattern)) unless Regexp === pattern
    
    start = 0
    ret = []
    
    while match = pattern.match_from(self, start)
      break if limited && limit - ret.size <= 1
      collapsed = match.collapsing?
      if !collapsed || (match.begin(0) != 0)
        ret << match.pre_match_from(last_match ? last_match.end(0) : 0)
        ret.push(*match.captures.compact)
      end
      if collapsed
        start += 1
      elsif last_match && last_match.collapsing?
        start = match.end(0) + 1
      else
        start = match.end(0)
      end
      last_match = match
    end
    if last_match
      ret << last_match.post_match
    elsif ret.empty?
      ret << self.dup
    end
    (ret.pop while ret[-1] == "") if limit == 0 || limit.nil?
    (ret.shift while ret[0] == "") if spaces
    ret = ret.map { |str| self.class.new(str) } if !self.instance_of?(String)
    ret = ret.map { |str| str.taint } if self.tainted?
    ret
  end

  # Builds a set of characters from the <i>*strings</i> parameter(s) using the
  # procedure described for <code>String#count</code>. Returns a new string
  # where runs of the same character that occur in this set are replaced by a
  # single character. If no arguments are given, all runs of identical
  # characters are replaced by a single character.
  # 
  #   "yellow moon".squeeze                  #=> "yelow mon"
  #   "  now   is  the".squeeze(" ")         #=> " now is the"
  #   "putters shoot balls".squeeze("m-z")   #=> "puters shot balls"
  def squeeze(*strings)
    (str = self.dup).squeeze!(*strings) || str
  end

  # Squeezes <i>self</i> in place, returning either <i>self</i>, or
  # <code>nil</code> if no changes were made.
  def squeeze!(*strings)
    self.modify!
    return if @bytes == 0
    
    new = []
    save = nil
    
    if strings.empty?
      each_byte do |c|
        new << (save = c).chr unless save == c
      end
    else
      last_end = 0
      last_match = nil
      pattern = tr_regex(strings)
      
      while match = pattern.match_from(self, last_end)
        unless save == match[0] && match.begin(0) == last_end
          new << match.pre_match_from(last_end) << (save = match[0]) 
        end
        last_end = match.begin(0) + 1
      end
      
      new << self[last_end..-1] if self[last_end..-1]
    end

    new = new.join
    new != self ? replace(new) : nil
  end

  # Returns a copy of <i>self</i> with leading and trailing whitespace removed.
  #    
  #   "    hello    ".strip   #=> "hello"
  #   "\tgoodbye\r\n".strip   #=> "goodbye"
  def strip
    (str = self.dup).strip! || str
  end
  
  # Removes leading and trailing whitespace from <i>self</i>. Returns
  # <code>nil</code> if <i>self</i> was not altered.
  def strip!
    left = lstrip!
    right = rstrip!
    left.nil? && right.nil? ? nil : self
  end

  # Returns a copy of <i>self</i> with the <em>first</em> occurrence of
  # <i>pattern</i> replaced with either <i>replacement</i> or the value of the
  # block. The <i>pattern</i> will typically be a <code>Regexp</code>; if it is
  # a <code>String</code> then no regular expression metacharacters will be
  # interpreted (that is <code>/\d/</code> will match a digit, but
  # <code>'\d'</code> will match a backslash followed by a 'd').
  #    
  # If the method call specifies <i>replacement</i>, special variables such as
  # <code>$&</code> will not be useful, as substitution into the string occurs
  # before the pattern match starts. However, the sequences <code>\1</code>,
  # <code>\2</code>, etc., may be used.
  #    
  # In the block form, the current match string is passed in as a parameter, and
  # variables such as <code>$1</code>, <code>$2</code>, <code>$`</code>,
  # <code>$&</code>, and <code>$'</code> will be set appropriately. The value
  # returned by the block will be substituted for the match on each call.
  #    
  # The result inherits any tainting in the original string or any supplied
  # replacement string.
  #    
  #   "hello".sub(/[aeiou]/, '*')               #=> "h*llo"
  #   "hello".sub(/([aeiou])/, '<\1>')          #=> "h<e>llo"
  #   "hello".sub(/./) {|s| s[0].to_s + ' ' }   #=> "104 ello"
  def sub(pattern, replacement = nil, &block)
    (str = self.dup).sub!(pattern, replacement, &block) || str
  end

  # Performs the substitutions of <code>String#sub</code> in place,
  # returning <i>self</i>, or <code>nil</code> if no substitutions were
  # performed.
  def sub!(pattern, replacement = nil)
    raise ArgumentError, "wrong number of arguments (1 for 2)" if !replacement && !block_given?
    raise ArgumentError, "wrong number of arguments (0 for 2)" if pattern.nil?
    
    out = self.dup
    if match = get_pattern(pattern, true).match(self)
      out = match.pre_match
      old_md = $~

      if replacement
        self.taint if replacement.tainted?
        replacement = StringValue(replacement).replace_slashes.to_sub_replacement(match)
      else
        old_str = self.dup
        replacement = yield(match[0].dup).to_s
        raise RuntimeError, "string modified" if old_str != self

        self.taint if replacement.tainted?
      end

      self.modify!
      out << replacement << match.post_match
      $~ = old_md
    end
    
    out = self.class.new(out) unless self.instance_of?(String)
    out == self ? nil : self.replace(out)
  end

  # Returns the successor to <i>self</i>. The successor is calculated by
  # incrementing characters starting from the rightmost alphanumeric (or
  # the rightmost character if there are no alphanumerics) in the
  # string. Incrementing a digit always results in another digit, and
  # incrementing a letter results in another letter of the same case.
  # Incrementing nonalphanumerics uses the underlying character set's
  # collating sequence.
  #    
  # If the increment generates a ``carry,'' the character to the left of
  # it is incremented. This process repeats until there is no carry,
  # adding an additional character if necessary.
  #    
  #   "abcd".succ        #=> "abce"
  #   "THX1138".succ     #=> "THX1139"
  #   "<<koala>>".succ   #=> "<<koalb>>"
  #   "1999zzz".succ     #=> "2000aaa"
  #   "ZZZ9999".succ     #=> "AAAA0000"
  #   "***".succ         #=> "**+"
  def succ
    return "".copy_properties(self) if length == 0
    out = self.dup

    start = length-1
    alnum = self[-1..-1] =~ /[a-zA-Z0-9]/
    while start >= 0       # can't break from a step or downto yet
      if out[start].isalnum
        break
      else
        start -= 1
      end
    end
    start = length-1 if start < 0
    
    carry = false
    c = 0
    start.step(0, -1) do |idx|
      c = out[idx]
      carry = true 
      if alnum && carry && c.chr !~ /[a-zA-Z0-9]/
        out[idx] = c
        next
      end
      last_alnum = idx
      if c == ?9
        c = ?0
      elsif c == ?Z
        c = ?A
      elsif c == ?z
        c = ?a
      else
        c = (c + 1) % 256
        carry = false if c != 0
      end
      out[idx] = c
      return out.copy_properties(self) if !carry
    end
    c = out[last_alnum]
    c += 1 if c == ?0 || c == 0
    out = out[0...last_alnum] + c.chr + out[last_alnum..-1]
    # work around for << not taking Fixnum
    return out.copy_properties(self)
  end

  # Equivalent to <code>String#succ</code>, but modifies the receiver in
  # place.
  def succ!
    replace(succ)
  end

  alias_method :next, :succ
  alias_method :next!, :succ!

  # Returns a basic <em>n</em>-bit checksum of the characters in <i>self</i>,
  # where <em>n</em> is the optional <code>Fixnum</code> parameter, defaulting
  # to 16. The result is simply the sum of the binary value of each character in
  # <i>self</i> modulo <code>2n - 1</code>. This is not a particularly good
  # checksum.
  def sum(bits = 16)
    bits = Type.coerce_to(bits, Integer, :to_int)
    sum = 0
    each_byte { |b| sum += b }
    sum & ((1 << bits) - 1)
  end

  # Returns a copy of <i>self</i> with uppercase alphabetic characters converted to
  # lowercase and lowercase characters converted to uppercase.
  #
  #   "Hello".swapcase          #=> "hELLO"
  #   "cYbEr_PuNk11".swapcase   #=> "CyBeR_pUnK11"
  def swapcase
    (str = self.dup).swapcase! || str
  end
  
  # Equivalent to <code>String#swapcase</code>, but modifies the receiver in
  # place, returning <i>self</i>, or <code>nil</code> if no changes were made.
  def swapcase!
    self.modify!
    return if @bytes == 0
  
    modified = false
  
    @bytes.times do |i|
      if @data[i].islower
        @data[i] = @data[i].toupper
        modified = true
      elsif @data[i].isupper
        @data[i] = @data[i].tolower
        modified = true
      end
    end
  
    modified ? self : nil
  end

  # Returns the <code>Symbol</code> corresponding to <i>self</i>, creating the
  # symbol if it did not previously exist. See <code>Symbol#id2name</code>.
  #    
  #   "Koala".intern         #=> :Koala
  #   s = 'cat'.to_sym       #=> :cat
  #   s == :cat              #=> true
  #   s = '@cat'.to_sym      #=> :@cat
  #   s == :@cat             #=> true
  #
  # This can also be used to create symbols that cannot be represented using the
  # <code>:xxx</code> notation.
  #    
  #   'cat and dog'.to_sym   #=> :"cat and dog"
  #--
  # TODO: Add taintedness-check
  #++
  def to_sym
    raise ArgumentError, "interning empty string" if self.empty?
    raise ArgumentError, "symbol string may not contain `\\0'" if self.include?("\x00")
    __symbol_lookup__
  end
  alias_method :intern, :to_sym

  # Returns the result of interpreting leading characters in <i>self</i> as an
  # integer base <i>base</i> (between 2 and 36). Extraneous characters past the
  # end of a valid number are ignored. If there is not a valid number at the
  # start of <i>self</i>, <code>0</code> is returned. This method never raises an
  # exception.
  #    
  #   "12345".to_i             #=> 12345
  #   "99 red balloons".to_i   #=> 99
  #   "0a".to_i                #=> 0
  #   "0a".to_i(16)            #=> 10
  #   "hello".to_i             #=> 0
  #   "1100101".to_i(2)        #=> 101
  #   "1100101".to_i(8)        #=> 294977
  #   "1100101".to_i(10)       #=> 1100101
  #   "1100101".to_i(16)       #=> 17826049
  def to_i(base = 10)
    base = Type.coerce_to(base, Integer, :to_int)
    raise ArgumentError, "illegal radix #{base}" if base < 0
    self.to_inum(base)
  end
  
  # Returns self if self is an instance of String,
  # else returns self converted to a String instance.
  def to_s
    self.class == String ? self : String.new(self)
  end
  alias_method :to_str, :to_s

  # Returns a copy of <i>self</i> with the characters in <i>from_str</i> replaced
  # by the corresponding characters in <i>to_str</i>. If <i>to_str</i> is
  # shorter than <i>from_str</i>, it is padded with its last character. Both
  # strings may use the c1--c2 notation to denote ranges of characters, and
  # <i>from_str</i> may start with a <code>^</code>, which denotes all
  # characters except those listed.
  #    
  #    "hello".tr('aeiou', '*')    #=> "h*ll*"
  #    "hello".tr('^aeiou', '*')   #=> "*e**o"
  #    "hello".tr('el', 'ip')      #=> "hippo"
  #    "hello".tr('a-y', 'b-z')    #=> "ifmmp"
  def tr(source, replacement)
    (str = self.dup).tr!(source, replacement) || str
  end

  # Translates <i>self</i> in place, using the same rules as
  # <code>String#tr</code>. Returns <i>self</i>, or <code>nil</code> if no
  # changes were made.
  def tr!(source, replacement)
    tr_trans(source, replacement, false)
  end

  # Processes a copy of <i>self</i> as described under <code>String#tr</code>,
  # then removes duplicate characters in regions that were affected by the
  # translation.
  #    
  #    "hello".tr_s('l', 'r')     #=> "hero"
  #    "hello".tr_s('el', '*')    #=> "h*o"
  #    "hello".tr_s('el', 'hx')   #=> "hhxo"
  def tr_s(source, replacement)
    (str = self.dup).tr_s!(source, replacement) || str
  end

  # Performs <code>String#tr_s</code> processing on <i>self</i> in place,
  # returning <i>self</i>, or <code>nil</code> if no changes were made.
  def tr_s!(source, replacement)
    tr_trans(source, replacement, true)
  end

  # Returns a copy of <i>self</i> with all lowercase letters replaced with their
  # uppercase counterparts. The operation is locale insensitive---only
  # characters ``a'' to ``z'' are affected.
  #    
  #   "hEllO".upcase   #=> "HELLO"
  def upcase
    (str = self.dup).upcase! || str
  end
  
  # Upcases the contents of <i>self</i>, returning <code>nil</code> if no changes
  # were made.
  def upcase!
    return if @bytes == 0
    self.modify!
  
    modified = false
  
    @bytes.times do |i|
      if @data[i].islower
        @data[i] = @data[i].toupper
        modified = true
      end
    end

    modified ? self : nil
  end
  


  def str_gsub(pattern, replacement, bang)
    raise ArgumentError, "wrong number of arguments (1 for 2)" unless replacement || block_given?
    raise ArgumentError, "wrong number of arguments (0 for 2)" unless pattern

    tainted = false

    if replacement
      tainted = replacement.tainted?
      replacement = StringValue(replacement).replace_slashes
      tainted ||= replacement.tainted?
    end
    
    pattern = get_pattern(pattern, true)
    copy = self.dup
    
    last_end = start = 0
    ret = []

    while match = pattern.match_from(self, start) and last_match = match
      ret << (match.pre_match_from(last_end) || "")
      
      if replacement
        ret << replacement.to_sub_replacement(match)
      else
        val = yield(match[0].dup)
        tainted ||= val.tainted?
        ret << val.to_s
        
        raise RuntimeError, "string modified" if self != copy
        $~ = match
      end
      
      tainted ||= val.tainted?
      
      last_end = match.end(0)
      start = match.collapsing? ? start + 1 : match.end(0)
    end
    
    $~ = last_match

    ret << self[start..-1] if self[start..-1]

    return if bang && !last_match

    str = ret.join
    str = self.class.new(str) unless self.instance_of?(String)
    str.taint if tainted || self.tainted?
    return bang ? replace(str) : str
  end


  def tr_trans(source, replacement, squeeze)
    source = StringValue(source).to_expanded_tr_string
    replacement = StringValue(replacement).to_expanded_tr_string

    self.modify!
    
    return self.delete!(source) if replacement.empty?
    return if @bytes == 0

    if replacement.length < source.length
      replacement << (replacement.empty? ? " " : replacement[-1,1]) * (source.length - replacement.length)
    end
    
    if source[0] == ?^ && source.length > 1
      trans = Array.new(256, 1)
      
      (1...source.size).each do |i|
        c = source[i]
        trans[c] = -1
      end
      
      c = replacement[-1]
      
      trans.each_index do |i|
        trans[i] = c if trans[i] >= 0
      end
    else
      trans = Array.new(256, -1)
      (0...source.size).each do |i|
        c = source[i]
        trans[c] = replacement[i]
      end
    end
    
    self.modify!
    modified = false
    
    if squeeze
      new = []
      last = nil

      (0...@bytes).each do |i|
        s = @data[i]
        if (c = trans[s]) >= 0
          next if last == c
          new << c.chr
          last = c
        else
          new << s.chr
          last = nil
        end
      end
      
      new = new.join
      return new != self ? replace(new) : nil
    else
      (0...@bytes).each do |i|
        s = @data[i]
        if (c = trans[s]) >= 0
          @data[i] = c
          modified = true
        end
      end
      
      return modified ? self : nil
    end
  end

  def scan_once(pattern, start)
    if match = pattern.match_from(self, start)
      start = match.collapsing? ? match.end(0) + 1 : match.end(0)
      return start, match.length == 1 ? match[0] : match.captures
    end
  end

  def to_sub_replacement(match)
    self.gsub(/\\[\d\&\`\'\+]/) do |x| 
      # x[-1,1] returns a character version of the last character
      case cap = x[-1,1]
      when "`"
        match.pre_match
      when "'"
        match.post_match
      when "+"
        match.captures.compact[-1].to_s
      else
        match[cap.to_i]
      end
    end
  end

  def to_inum(base, check = false)
    i = 0
    # ignore only leading whitespaces
    if check
      while i < @bytes && @data[i].isspace
        i += 1
      end
    # ignore leading whitespaces and underscores
    else
      while i < @bytes && (@data[i].isspace || @data[i] == ?_)
        i += 1
      end
    end
    
    negative = false
    if @data[i] == ?+
      i += 1
    elsif @data[i] == ?-
      negative = true
      i += 1
    end
    
    if @data[i] == ?+ || @data[i] == ?-
      raise ArgumentError, "invalid value for Integer: #{self.inspect}" if check
      return 0
    end
    
    if base <= 0
      if @data[i] == ?0
        case @data[i+1]
        when ?x, ?X
          base = 16
        when ?b, ?B
          base = 2
        when ?o, ?O
          base = 8
        when ?d, ?D
          base = 10
        else
          base = 8
        end
      elsif base < -1
        base = -base
      else
        base = 10
      end
    end
    
    case base
    when 2
      i += 2 if @data[i] == ?0 && (@data[i+1] == ?b || @data[i+1] == ?B)
    when 8
      i += 2 if @data[i] == ?0 && (@data[i+1] == ?o || @data[i+1] == ?O)
    when 10
      i += 2 if @data[i] == ?0 && (@data[i+1] == ?d || @data[i+1] == ?D)
    when 16
      i += 2 if @data[i] == ?0 && (@data[i+1] == ?x || @data[i+1] == ?X)
    else
      raise ArgumentError, "illegal radix #{base}" if (base < 2 || 36 < base)
    end
    
    result = 0
    i.upto(@bytes - 1) do |index|
      char = @data[index]

      if char.isspace || (!check && char == ?_) 
        next
      elsif char >= ?0 && char <= ?9
        value = (char - ?0)
      elsif char >= ?A && char <= ?Z
        value = (char - ?A + 10)
      elsif char >= ?a && char <= ?z
        value = (char - ?a + 10)
      # An invalid character.
      else
        raise ArgumentError, "invalid value for Integer: #{self.inspect}" if check
        return negative ? -result : result
      end

      if value >= base
        raise ArgumentError, "invalid value for Integer: #{self.inspect}" if check
        return negative ? -result : result
      end

      result *= base
      result += value
    end
    
    return negative ? -result : result
  end

  def tr_regex(strings)
    strings = strings.map do |string|
      string = StringValue(string)
      if string.empty?
        "[.]"
      elsif string == "^"
        "[\\^]"
      else
        if string.size > 1 && string.data[0] == ?^
          string = "^" << string[1..-1].gsub(/.-./) { |r| (r[2] >= r[0]) ? r : "." }
        else
          string = string.gsub(/.-./) { |r| (r[2] >= r[0]) ? r : "." }
        end
        string = "[#{string.gsub(/[\[\]\/\\]/) {|x| "\\#{x}"}}]"
        string.gsub(/(.)-(.)-/, '\\1-\\2\-')
      end
    end
    /[#{strings.join("&&")}]/
  end

  def to_expanded_tr_string
    return self unless self =~ /.-./

    if @bytes > 1 && @data[0] == ?^
      "^" << self[1..-1].gsub(/.-./) { |r| (r[0]..r[2]).to_a.map { |c| c.chr } }
    else
      self.gsub(/.-./) { |r| (r[0]..r[2]).to_a.map { |c| c.chr } }
    end
  end
  
  def smart_chomp!
    length = @bytes - 1
    if @data[length] == ?\n
      length -= 1
      length -= 1 if length > 0 && @data[length] == ?\r
    elsif @data[length] == ?\r
      length -= 1
    else
      return nil
    end
    
    return replace(substring(0, length + 1))
  end

  def justify(integer, direction, padstr = " ")
    integer = Type.coerce_to(integer, Integer, :to_int) unless integer.is_a?(Fixnum)
    padstr = StringValue(padstr)
    
    raise ArgumentError, "zero width padding" if padstr.length == 0

    padsize = integer - self.size
    padsize = padsize > 0 ? padsize : 0
    case direction
    when :right
      dup.insert(0, padstr.to_padding(padsize))
    when :left
      dup.insert(-1, padstr.to_padding(padsize))
    when :center
      lpad = padstr.to_padding((padsize / 2.0).floor)
      rpad = padstr.to_padding((padsize / 2.0).ceil)
      dup.insert(0, lpad).insert(-1, rpad)
    end
  end
  
  # Convert this string to a padstring for use in String#justify.
  def to_padding(padsize)
    if padsize != 0
      (self * ((padsize / self.size) + 1)).slice(0, padsize)
    else
      ""
    end
  end

  # Unshares shared strings.
  def modify!
    if @shared
      @data = @data.dup
      @shared = nil
    end
  end

  def subpattern(pattern, capture)
    # TODO: A part of the functionality here should go into MatchData#[]
    return if (match = pattern.match(self)).nil? || capture >= match.size
    if capture < 0
      capture += match.size
      return if capture <= 0
    end
    
    start = match.begin(capture)
    count = match.end(capture) - match.begin(capture)
    str = self.substring(start, count)
    str.taint if pattern.tainted?
    str
  end

  def subpattern_set(pattern, capture, replacement)
    unless match = pattern.match(self)
      raise IndexError, "regexp not matched"
    end
    
    raise IndexError, "index #{index} out of regexp" if capture >= match.size
    
    if capture < 0
      raise IndexError, "index #{index} out of regexp" if -capture >= match.size
      capture += match.size
    end
    
    start  = match.begin(capture)
    length = match.end(capture) - start 
    self.splice(start, length, replacement)
  end

  def substring(start, count)
    return if count < 0 || start > @bytes || -start > @bytes
    
    start += @bytes if start < 0
    
    count = @bytes - start if start + count > @bytes
    count = 0 if count < 0

    str = self.class.allocate
    str.taint if self.tainted?
    str.put 0, count
    str.put 1, count
    if count == 0
      str.put(3, ByteArray.new(0))
    else
      str.put(3, @data.fetch_bytes(start, count))
    end
    
    return str
  end

  def splice(start, count, replacement)
    raise IndexError, "negative length #{count}" if count < 0
    self.modify!
    raise IndexError, "index #{start} out of string" if @bytes < start || -start > @bytes
    
    start += @bytes if start < 0
    count = @bytes - start if start + count > @bytes
    
    # TODO: Optimize this by using the @data ByteArray directly?
    output = ""
    output << substring(0, start) if start != 0
    output << StringValue(replacement)
    output << substring(start + count, @bytes - (start + count)) if start + count < @bytes
      
    replace(output)
  end

  #---
  # NOTE: This overwrites String#dup defined in bootstrap.
  # TODO: Remove me and make string_dup check taint and freeze.
  # TODO: Make string_dup compatible with String subclasses
  #+++
  def dup
    if self.instance_of? String
      out = Ruby.asm "push self\nstring_dup\n"
    else
      out = self.class.new(self)
    end
    
    out.taint if self.tainted?
    return out
  end

  # FIXME - Make Unicode-safe
  def codepoints
    chars = []
    @bytes.times do |pos|
      chars << self.substring(pos, 1)
    end
    chars
  end

  def prefix?(pre)
    return false if pre.size > @bytes
    sub = substring(0, pre.size)
    pre == sub
  end
  
  def suffix?(pre)
    return false if pre.size >= @bytes
    sub = substring(@bytes - pre.size, pre.size)
    pre == sub
  end

  # TODO: inspect is NOT dump!
  def dump
    kcode = $KCODE
    $KCODE = "NONE"
    ret = self.inspect.copy_properties(self)
    $KCODE = $KCODE
    ret
  end
  
  def copy_properties(original)
    ret = self.dup
    ret.taint if original.tainted?
    unless original.instance_of?(String)
      ret = original.class.new(ret)
    end
    ret
  end
  
  def to_sexp(name="(eval)",line=1,newlines=true)
    out = to_sexp_full(name, line, newlines)
    if out.kind_of? Tuple
      exc = SyntaxError.new out.at(0)
      exc.import_position out.at(1), out.at(2)
      raise exc
    end
    return out
  end

  def shared!
    @shared = true
  end
  
  # Replaces the contents and taintedness of <i>string</i> with the corresponding
  # values in <i>other</i> if they differ.
  # 
  #   s = "hello"           #=> "hello"
  #   s.replace_if "hello"  #=> nil
  #   s                     #=> "hello"
  #   s.replace_if "world"  #=> "world"
  #   s                     #=> "world"
  def replace_if(other)
    self == other ? nil : replace(other)
  end
  
  def get_pattern(pattern, quote = false)
    unless pattern.is_a?(String) || pattern.is_a?(Regexp)
      if pattern.respond_to?(:to_str)
        pattern = pattern.to_str
      else
        raise TypeError, "wrong argument type #{pattern.class} (expected Regexp)"
      end
    end
    pattern = Regexp.quote(pattern) if quote && pattern.is_a?(String)
    pattern = Regexp.new(pattern) unless pattern.is_a?(Regexp)
    pattern
  end

  # mini-gsub created purely to handle slashes because using gsub recursively was causing segfaults
  # TODO: make it work correctly
  def replace_slashes
    start = 0
    ret = ""
    while(match = /\\\\/.match_from(self, start))
      ret << match.pre_match_from(start)
      ret << '\\'
      start = match.end(0)
    end
    ret << self[start..-1]
    ret
  end

  def without_changing_regex_global
    old_md = $~
    yield
    $~ = old_md
  end

  # def rindex(arg, finish = nil )
  #   arg = StringValue(arg) unless [Fixnum, String, Regexp].include?(arg.class)
  #   return (finish || self.size) if arg.is_a?(String) && arg.empty?
  #   
  #   arg_finish = finish
  #   if finish
  #     at_end = 0
  #     finish = finish.coerce_to(Integer, :to_int)
  #     finish += @bytes if finish < 0
  #     return nil if finish < 0
  #     finish, at_end = @bytes - 1, 1 if finish >= @bytes
  #   else
  #     finish, at_end = @bytes - 1, 1
  #   end
  # 
  #   arg = arg[0] if arg.is_a?(String) && arg.size == 1
  #   
  #   if arg.is_a?(Fixnum)
  #     finish.step(0, -1) do |idx|
  #       return idx if @data[idx] == arg
  #     end
  #   elsif arg.is_a? String
  #     # return nil if arg.length > finish + at_end
  #     len   = arg.length
  #     start = finish - len + at_end
  #     start = 0 if start < 0 && finish >= 0
  #     start.step(0, -1) do |idx|
  #       if @data[idx] == arg.data[0]
  #         return idx if substring(idx,len) == arg
  #       end
  #     end
  #   elsif arg.is_a? Regexp
  #     mstr = self[0..finish]
  #     offset = nil
  #     while m = arg.match(mstr)
  #       break if m.begin(0) == m.end(0)
  #       offset = offset ? offset += m.begin(0) + len : m.begin(0)
  #       len = m.end(0) - m.begin(0)
  #       mstr = m.post_match
  #     end
  #     return offset
  #   else
  #     raise TypeError.new("String#index cannot accept #{arg.class} objects")
  #   end
  #   return nil
  # end

  def full_to_i
    err = "invalid value for Integer: #{self.inspect}"
    raise ArgumentError, err if self.match(/__/) || self.empty?
    case self
    when /^[-+]?0(\d|_\d)/
      raise ArgumentError, err if self =~ /[^0-7_]/
      to_i(8)
    when /^[-+]?0x[a-f\d]/i
      after = self.match(/^[-+]?0x/i)
      raise ArgumentError, err if /([^0-9a-f_])/i.match_from(self, after.end(0))
      to_i(16)
    when /^[-+]?0b[01]/i
      after = self.match(/^[-+]?0b/i)      
      raise ArgumentError, err if /[^01_]/.match_from(self, after.end(0))
      to_i(2)
    when /^[-+]?\d/
      raise ArgumentError, err if self.match(/[^0-9_]/)
      to_i(10)
    else
      raise ArgumentError, err
    end
  end
  
  def upto(stop)
    stop = StringValue(stop)
    raise LocalJumpError, "no block given" unless block_given?

    return self if self > stop

    str = self.dup
    loop do
      yield str.dup
      str.succ!
      break if str.size > stop.size || str > stop
    end
    self
  end

=begin

  # Should be added when Crypt is required
  def crypt(other_str)
    raise NotImplementedError
  end


  def unpack(format) # => anArray
    raise NotImplementedError
  end
=end

end
