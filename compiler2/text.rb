class Compiler
  class TextGenerator
    
    @@method_id = 0
    
    def initialize
      @text = ""
      @label = 0
      @other_methods = {}
      @ip = 0
      @file = "(unknown)"
      @line = 0
    end
    
    attr_reader :text, :ip, :file, :line
    attr_accessor :redo, :retry, :break
    
    def advanced_since?(old)
      old < @ip
    end
    
    def advance(count=1)
      @ip += count
    end
        
    class Label
      def initialize(gen, idx)
        @gen = gen
        @index = idx
      end
      
      attr_reader :index
      
      def set!
        @gen.set_label(@index)
      end
      
      def inspect
        "l#{@index}"
      end
    end
    
    def new_label
      Label.new(self, @label += 1)
    end
    
    def set_label(idx)
      @text << "l#{idx}:\n"
    end
        
    def run(node)
      node.bytecode(self)
    end
    
    def set_line(line, file)
      @file, @line = file, line
      @text << "#line #{line}\n"
    end
    
    def close
      return if @other_methods.empty?
      @other_methods.each_pair do |i,m|
        @text << "\n:==== Method #{i} ====\n"
        @text << m.generator.text
        @text << "\n"
      end
    end
    
    def method_missing(op, *args)
      if args.empty?
        @text << "#{op}\n"
        advance
      else
        @text << "#{op} #{args.join(' ', :inspect)}\n"
        advance 1 + args.size
      end
    end
    
    def push(what)
      @text << "push #{what}\n"
      advance
    end
    
    def send(meth, count, priv=false)
      @text << "send #{meth} #{count}"
      if priv
        @text << " true ; allow private\n"
      else
        @text << "\n"
      end
      advance
    end
    
    def dup
      method_missing :dup
    end
    
    def push_literal(lit)
      if lit.kind_of? Compiler::MethodDescription
        @text << "push_literal #<Method #{@@method_id}>\n"
        
        @other_methods[@@method_id] = lit
        @@method_id += 1
        advance
      else
        method_missing :push_literal, lit
      end
    end
    
    def as_primitive(name)
      @text << "#primitive #{name}\n"
    end
    
  end
end