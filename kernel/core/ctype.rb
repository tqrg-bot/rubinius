module CType
  
  # isspace, islower, ... are not in MRI core library.
  # See specs in spec/shotgun/ctype_spec.rb
  def isspace
    self == ?\s or self == ?\n or self == ?\t or self == ?\r or self == ?\f or self == ?\v
  end

  def isupper
    self.between?(?A, ?Z)
  end

  def islower
    self.between?(?a, ?z)
  end
  
  def isdigit
    self.between?(?0, ?9)
  end
  
  def isalnum
    islower or isupper or isdigit
  end
  
  def toupper
    self.islower ? self - ?\s : self
  end
  
  def tolower
    self.isupper ? self + ?\s : self
  end
end
