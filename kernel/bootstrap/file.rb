class File < IO
  def self.open_with_mode(path, mode, perm)
    Ruby.primitive :io_open
  end
  
  def self.unlink(path)
    Ruby.primitive :file_unlink
  end
  
  def self.to_sexp_full(path, newlines)
    Ruby.primitive :file_to_sexp
  end
  
  class Stat
    def self.stat(path, follow_links)
      Ruby.primitive :stat_file
    end
  end
  
end
