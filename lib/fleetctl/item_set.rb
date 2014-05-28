module Fleet
  class ItemSet < Set
    def add_or_find(obj)
      res = self.detect { |member| member == obj }
      if res
        res
      else
        add(obj)
        obj
      end
    end
  end
end