class String
  def blank?() strip.empty? end
  
  def mb_chars() self end
end

class NilClass
  def blank?() true end
end

class FalseClass
  def blank?() true end
end

class Array
  alias_method :blank?, :empty?
end

class Hash
  alias_method :blank?, :empty?
end

class Object
  def blank?()   false   end
  def present?() !blank? end
end
