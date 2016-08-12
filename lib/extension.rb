module Extension
  def self.included(base)
    base.extend(Extension)
  end
  # def after_save
  #   test2
  # end
  def test2
    raise "Hello World"
  end
  def test3
    puts "Hello World Test 3"
  end
end
