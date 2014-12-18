class Object
  def then method=nil
    if block_given?
      self && yield(self)
    else
      if self
        if self.class.ancestors.include? Hash
          self[method]
        elsif self.respond_to? method
          self.send method
        else
          nil
        end
      else
        nil
      end
    end
  end

  def chain *methods
    methods.reduce(self, :then)
  end
end