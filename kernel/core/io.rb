class IOError < StandardError
end

class IO
  
  BufferSize = 8096

  SEEK_SET = Platform::POSIX.seek_set
  SEEK_CUR = Platform::POSIX.seek_cur
  SEEK_END = Platform::POSIX.seek_end
  
  def initialize(fd)
    @descriptor = fd
  end
  
  ivar_as_index :__ivars__ => 0, :descriptor => 1, :buffer => 2, :mode => 3
  def __ivars__ ; @__ivars__  ; end
    
  def inspect
    "#<#{self.class}:0x#{object_id.to_s(16)}>"
  end
  
  def fileno
    @descriptor
  end
  
  alias_method :to_i, :fileno
  
  def puts(*args)
    if args.empty?
      write DEFAULT_RECORD_SEPARATOR
    else
      args.each do |arg|
        if arg.nil?
          str = "nil"
        elsif RecursionGuard.inspecting?(arg)
          str = "[...]"
        elsif arg.kind_of?(Array)
          RecursionGuard.inspect(arg) do
            arg.each do |a|
              puts a
            end
          end
        else
          str = arg.to_s
        end
        
        if str
          write str
          write DEFAULT_RECORD_SEPARATOR unless str.suffix?(DEFAULT_RECORD_SEPARATOR)
        end
      end
    end

    nil
  end
  
  def <<(obj)
    write(obj.to_s)
    return self
  end
  
  alias_method :print, :<<
    
  def sysread(size, buf=nil)
    buf = String.new(size) unless buf
    chan = Channel.new
    Scheduler.send_on_readable chan, self, buf, size
    raise EOFError if chan.receive.nil?
    return buf
  end

  alias_method :readpartial, :sysread
    
  alias_method :syswrite, :write

  def read(size=nil, buf=nil)
    if size
      buf = String.new(size) unless buf
      chan = Channel.new
      Scheduler.send_on_readable chan, self, buf, size
      return nil if chan.receive.nil?
      return buf
    else
      chunk = String.new(BufferSize)
      out = ""
      loop do
        chan = Channel.new
        Scheduler.send_on_readable chan, self, chunk, BufferSize
        
        return out if chan.receive.nil?
                
        out << chunk
      end
    end
  end
  
  def close
    raise IOError, "Instance of IO already closed" if closed?
    io_close
  end
  
  def descriptor
    @descriptor
  end
    
  def closed?
    @descriptor == -1
  end
  
  # The current implementation does no buffering, so we're always
  # in sync mode.
  def sync=(v)
  end
  
  def sync
    true
  end
  
  def flush
    true
  end
  
  def gets(sep=$/)
    $_ = gets_helper(sep)
  end

  def each(sep=$/)
    while line = gets_helper(sep)
      yield line
    end
  end

  alias_method :each_line, :each

  # Several methods use similar rules for reading strings from IO, but
  # differ slightly. This helper is an extraction of the code.
  #
  # TODO: make this private. Private methods have problems in core right now.
  def gets_helper(sep)
    if sep.nil?
      out = read
    elsif sep.empty?
      out = ''
      while true
        cur = read(1)
        break if cur != $/
      end
      prev = ''
      while cur
        out << cur
        break if (cur == $/ && prev == $/)
        prev = cur
        cur = read(1)
      end
    else
      out = ''
      begin
        cur = read(1)
        break unless cur
        out << cur
      end until out[-sep.size,sep.size] == sep
    end
    return (out.nil? || out.empty? ? nil : out)
  end

  def readlines(sep=$/)
    ary = Array.new
    while line = gets(sep)
      ary << line
    end
    return ary
  end
  
  def self.readlines(name, sep_string = $/)
    io = File.open(StringValue(name), 'r')
    return if io.nil?
    
    begin
      io.readlines(sep_string)
    ensure
      io.close
    end
  end
  
  def self.foreach(name, sep_string = $/,&block)
    io = File.open(StringValue(name), 'r')
    sep = StringValue(sep_string)
    begin
      while(line = io.gets(sep))
        yield line
      end
    ensure
      io.close
    end
  end
  
  def self.pipe
    lhs = IO.allocate
    rhs = IO.allocate
    out = create_pipe(lhs, rhs)
    return [lhs, rhs]
  end

  def self.for_fd(fd)
    self.new(fd)
  end

  def self.open(*args)
    o = self.new(*args)

    return o unless block_given?

    begin
      yield o
    ensure
      o.close unless o.closed?
    end
  end
  
  private :io_close
end
