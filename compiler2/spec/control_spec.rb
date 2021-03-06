require File.dirname(__FILE__) + "/helper.rb"

describe Compiler do
  it "compiles if/end" do
    gen [:if, [:true], [:fixnum, 10], nil] do |g|
      g.push :true
      els = g.new_label
      fin = g.new_label
      g.gif els
      g.push 10
      g.goto fin
      els.set!
      g.push :nil
      fin.set!
    end
  end
  
  it "compiles if/else/end" do
    gen [:if, [:true], [:fixnum, 10], [:fixnum, 12]] do |g|
      g.push :true
      els = g.new_label
      fin = g.new_label
      g.gif els
      g.push 10
      g.goto fin
      els.set!
      g.push 12
      fin.set!
    end
  end
  
  it "compiles unless/end" do
    gen [:if, [:true], nil, [:fixnum, 12]] do |g|
      g.push :true
      els = g.new_label
      fin = g.new_label
      g.git els
      g.push 12
      g.goto fin
      els.set!
      g.push :nil
      fin.set!
    end
  end
  
  it "compiles a stupid if" do
    gen [:if, [:true], nil, nil] do |g|
      g.push :true
      g.pop
      g.push :nil
    end
  end
  
  it "compiles a normal while" do
    gen [:while, [:true], [:fixnum, 12], true] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      g.redo = g.new_label
      
      
      top.set!
      g.push :true
      g.gif fin
      g.redo.set!
      g.push 12
      g.pop
      g.goto top
      
      fin.set!
      g.push :nil
      
      # Break
      g.new_label.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles a post while" do
    gen [:while, [:true], [:fixnum, 12], false] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      
      top.set!
      g.push 12
      g.pop
      g.new_label.set! # next  
      g.push :true
      g.gif fin
      g.goto top
      
      fin.set!
      g.push :nil
      
      # Break
      g.new_label.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles a normal until" do
    gen [:until, [:true], [:fixnum, 12], true] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      g.redo = g.new_label
      
      top.set!
      g.push :true
      g.git fin
      g.redo.set!
      g.push 12
      g.pop
      g.goto top
      
      fin.set!
      g.push :nil
      
      # Break
      g.new_label.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles a post until" do
    gen [:until, [:true], [:fixnum, 12], false] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      
      top.set!
      g.push 12
      g.pop
      g.new_label.set! # next  
      g.push :true
      g.git fin
      g.goto top
      
      fin.set!
      g.push :nil
      
      # Break
      g.new_label.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles a series of expressions" do
    gen [:block, [:fixnum, 12], [:fixnum, 13], [:true]] do |g|
      g.push 12
      g.pop
      g.push 13
      g.pop
      g.push :true
    end
  end
  
  it "compiles a scope" do
    gen [:scope, [:fixnum, 12], []] do |g|
      g.push 12
    end
  end
  
  it "compiles loop {} directly" do
    gen [:iter, [:fcall, :loop], nil, [:fixnum, 12]] do |g|
      g.push_modifiers
      
      top = g.new_label
      top.set!
      g.push 12
      g.pop
      g.goto top
      g.new_label.set! # break 
      
      g.pop_modifiers
    end
  end
  
  
  it "compiles break in a control" do
    gen [:while, [:true], [:block, [:fixnum, 12], [:break]], true] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      g.redo = g.new_label
      g.break = g.new_label
      
      top.set!
      g.push :true
      g.gif fin
      g.redo.set!
      g.push 12
      g.pop
      g.push :nil
      g.goto g.break
      g.pop
      g.goto top
      
      fin.set!
      g.push :nil
      
      g.break.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles break in a block" do
    gen [:iter, [:fcall, :go], nil, [:block, [:fixnum, 12], [:break]]] do |g|
      iter = description do |d|
        d.pop
        d.new_label.set! # redo
        d.push 12
        d.pop
        d.push :nil
        d.soft_return
        d.soft_return
      end
      
      g.push_literal iter
      g.create_block2
      g.push :self
      g.send_with_block :go, 0, true
    end
  end
  
  it "compiles an unexpected break" do
    gen [:break] do |g|
      g.push :nil
      g.pop
      g.push_const :Compile
      g.send :__unexpected_break__, 0
    end
  end
  
  it "compiles redo in a while" do |g|
    gen [:while, [:true], [:block, [:fixnum, 12], [:redo]], true] do |g|
      g.push_modifiers
      
      top = g.new_label
      fin = g.new_label
      g.redo = g.new_label
      
      top.set!
      g.push :true
      g.gif fin
      g.redo.set!
      g.push 12
      g.pop
      g.goto g.redo
      g.pop
      g.goto top
      
      fin.set!
      g.push :nil
      
      # Break
      g.new_label.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles redo in a block" do
    gen [:iter, [:fcall, :go], nil, [:block, [:fixnum, 12], [:redo]]] do |g|
      iter = description do |d|
        d.pop
        d.redo = d.new_label
        d.redo.set!
        d.push 12
        d.pop
        d.goto d.redo
        d.soft_return
      end
      
      g.push_literal iter
      g.create_block2
      g.push :self
      g.send_with_block :go, 0, true
    end
  end
  
  it "compiles an invalid redo" do
    gen [:redo] do |g|
      g.push_literal "redo used in invalid context" 
      g.push_const :LocalJumpError
      g.push :self
      g.send :raise, 2, true
    end
  end
  
  it "compiles a simple case" do
    x = [:case, [:true], [[:when, [:array, [:const, :Fixnum]], [:fixnum, 12]]]]
    gen x do |g|
      nxt = g.new_label
      fin = g.new_label
      
      g.push :true
      g.dup
      
      g.push_const :Fixnum
      g.send :===, 1
      
      g.gif nxt
      
      g.pop
      g.push 12
      g.goto fin
      
      nxt.set!
      g.pop
      g.push :nil
      fin.set!
    end
  end
  
  it "compiles a case with multiple conditions" do
    x = [:case, [:true], [
           [:when, [:array, [:const, :Fixnum], [:const, :String]], 
               [:fixnum, 12]],
        ]]
        
    gen x do |g|
      nxt  = g.new_label
      fin  = g.new_label
      body = g.new_label
      
      g.push :true
      
      g.dup
      g.push_const :Fixnum
      g.send :===, 1
      g.git body
      
      g.dup
      g.push_const :String
      g.send :===, 1
      g.git body
      g.goto nxt

      body.set!
      g.pop
      g.push 12
      g.goto fin
      
      nxt.set!
      g.pop
      g.push :nil
      fin.set!
    end
    
  end
  
  it "compiles a case with multiple whens" do
    x = [:case, [:true], [
           [:when, [:array, [:const, :Fixnum]], 
               [:fixnum, 12]],
           [:when, [:array, [:const, :String]],
               [:fixnum, 13]]
        ]]
    
    gen x do |g|
      nxt1 = g.new_label
      nxt2 = g.new_label
      fin =  g.new_label
      
      g.push :true
      
      g.dup
      g.push_const :Fixnum
      g.send :===, 1
      
      g.gif nxt1
      
      g.pop
      g.push 12
      g.goto fin
      
      nxt1.set!
      g.dup
      g.push_const :String
      g.send :===, 1
      
      g.gif nxt2
      
      g.pop
      g.push 13
      g.goto fin
      
      nxt2.set!
      g.pop
      g.push :nil
      fin.set!
    end
    
  end
  
  it "compiles a case with an else" do
    x = [:case, [:true], [
           [:when, [:array, [:const, :Fixnum]], 
               [:fixnum, 12]],
        ], [:fixnum, 14]]
    
    gen x do |g|
      nxt = g.new_label
      fin = g.new_label
      
      g.push :true
      g.dup
      
      g.push_const :Fixnum
      g.send :===, 1
      
      g.gif nxt
      
      g.pop
      g.push 12
      g.goto fin
      
      nxt.set!
      g.pop
      g.push 14
      fin.set!
    end
    
  end
  
  it "compiles a case with a splat" do
    x = [:case, [:true], [
           [:when, [:array, [:when, [:vcall, :things], nil]], 
               [:fixnum, 12]],
        ]]
    
    gen x do |g|
      body = g.new_label
      nxt =  g.new_label
      fin =  g.new_label
      
      g.push :true
      
      g.dup
      g.push :self
      g.send :things, 0, true
      g.cast_array
      g.send :__matches_when__, 1
      g.git body
            
      g.goto nxt
      
      body.set!
      g.pop
      g.push 12
      g.goto fin
      
      nxt.set!
      g.pop
      g.push :nil
      fin.set!
    end
  end
  
  it "compiles a case with normal conditions and a splat" do
    x = [:case, [:true], [
           [:when, [:array, [:const, :String], [:when, [:vcall, :things], nil]], 
               [:fixnum, 12]],
        ]]
    
    gen x do |g|
      body = g.new_label
      nxt =  g.new_label
      fin =  g.new_label
      
      g.push :true
      
      g.dup
      g.push_const :String
      g.send :===, 1
      g.git body
      
      g.dup
      g.push :self
      g.send :things, 0, true
      g.cast_array
      g.send :__matches_when__, 1
      g.git body
            
      g.goto nxt
      
      body.set!
      g.pop
      g.push 12
      g.goto fin
      
      nxt.set!
      g.pop
      g.push :nil
      fin.set!
    end
  end
  
  it "compiles 'return'" do
    gen [:return] do |g|
      g.push :nil
      g.sret
    end
  end
  
  it "compiles 'return 12'" do
    gen [:return, [:fixnum, 12]] do |g|
      g.push 12
      g.sret
    end
  end
  
  it "compiles 'begin; 12; rescue; return 13; end'" do  
    x = [:rescue, [:fixnum, 12], 
          [:resbody, [:array, [:const, :String]],
             [:return, [:fixnum, 13]], nil
          ]
        ]
        
    gen x do |g|
      g.push_modifiers
      
      exc_start = g.new_label
      exc_handle = g.new_label
      
      fin = g.new_label
      rr = g.new_label
      last = g.new_label
      
      exc_start.set!
      g.push 12
      g.goto fin
      
      exc_handle.set!
      g.push_exception
      g.push_const :String
      g.send :===, 1
      body = g.new_label
      
      g.git body
      g.goto rr
      body.set!
      g.clear_exception
      g.push 13
      g.sret
      g.goto last
      
      rr.set!
      
      g.push_exception
      g.raise_exc
      
      fin.set!
      
      last.set!
      
      g.pop_modifiers
    end
  end
  
  it "compiles return in a block" do
    gen [:iter, [:fcall, :go], nil, [:block, [:return, [:fixnum, 12]]]] do |g|
      iter = description do |d|
        d.pop
        d.new_label.set! # redo
        d.push 12
        d.ret
        d.soft_return
      end
      
      g.push_literal iter
      g.create_block2
      g.push :self
      g.send_with_block :go, 0, true
    end
  end
  
  it "compiles 'return 1, 2, *c'" do
    x = [:return, [:argscat, 
           [:array, [:fixnum, 1], [:fixnum, 2]],
           [:vcall, :c]]]
    gen x do |g|
      g.push :self
      g.send :c, 0, true
      g.cast_array
      
      g.push 1
      g.push 2
      g.make_array 2
      g.send :+, 1
      g.sret
    end
  end
end
