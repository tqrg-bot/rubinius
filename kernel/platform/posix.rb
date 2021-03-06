# depends on: ffi.rb

module Platform::POSIX
  
  def self.add(ret, name, *args)
    attach_function nil, name, args, ret
  end
  
  # errors
  attach_function nil, 'ffi_errno', :errno, [], :int
  attach_function nil, 'strerror', [:int], :string
  attach_function nil, 'perror', [:string], :void
  
  # memory
  add :pointer, 'malloc',  :int
  add :pointer, 'realloc', :pointer, :int
  add :void,    'free',    :pointer 
  add :pointer, 'memset',  :pointer, :int, :int 
    
  # rand
  attach_function nil, 'srand', [:uint], :void
  attach_function nil, 'rand',  [], :int
  
  # file system
  attach_function nil, 'access', [:string, :int], :int
  attach_function nil, 'chmod',  [:string, :int], :int
  attach_function nil, 'fchmod', [:int, :int], :int
  attach_function nil, 'unlink', [:string], :int
  attach_function nil, 'getcwd', [:string, :int], :string
  attach_function nil, 'umask', [:int], :int
  attach_function nil, 'link', [:string, :string], :int
  attach_function nil, 'readlink', [:string, :string, :int], :int
  attach_function nil, 'rename', [:string, :string], :int
  
  # directories
  attach_function nil, 'chdir', [:string], :int
  attach_function nil, 'opendir',  [:string], :pointer
  attach_function nil, 'readdir',  [:pointer], :pointer
  attach_function nil, 'rewinddir',  [:pointer], :void
  attach_function nil, 'closedir', [:pointer], :int
  attach_function nil, 'mkdir', [:string, :short], :int
  attach_function nil, 'rmdir', [:string], :int
  
  # File/IO
  #   opening/closing
  attach_function nil, 'fdopen', [:int, :string], :pointer
  attach_function nil, 'fopen',  [:string, :string], :pointer
  attach_function nil, 'fclose', [:pointer], :int
  
  #   buffering
  attach_function nil, 'fflush', [:pointer], :int
  
  #   inspecting
  attach_function nil, 'fileno', [:pointer], :int
  attach_function nil, 'feof',   [:pointer], :int
  attach_function nil, 'ferror', [:pointer], :int
  attach_function nil, 'clearerr', [:pointer], :void
  attach_function nil, 'fseek',  [:pointer, :int, :int], :int
  attach_function nil, 'ftell',  [:pointer], :int
  
  #   reading
  attach_function nil, 'fread',   [:string, :int, :int, :pointer], :int
  attach_function nil, 'fgets',   [:string, :int, :pointer], :void
  attach_function nil, 'fgetc',   [:pointer], :int
  
  #   writing
  attach_function nil, 'fwrite',  [:string, :int, :int, :pointer], :int
  attach_function nil, 'ungetc',  [:int, :pointer], :int
  
  #   constants
  attach_function nil, 'ffi_seek_set', :seek_set, [], :int
  attach_function nil, 'ffi_seek_cur', :seek_cur, [], :int
  attach_function nil, 'ffi_seek_end', :seek_end, [], :int
  
  #   formatted strings
  attach_function nil, 'ffi_sprintf_f', :sprintf_f, [:double, :int, :string], :strptr
  attach_function nil, 'ffi_sprintf_d', :sprintf_d, [:int, :int, :string], :strptr
end
