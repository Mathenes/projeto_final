#https://gist.github.com/yuya-takeyama/812489
module BinaryTree
  class Node
    attr_accessor :father
    attr_reader :element, :left, :right

    include Enumerable

    def initialize(element)
      @element = element
    end

    def size
      size = 1
      size += @left.size  unless left.nil?
      size += @right.size unless right.nil?
      size
    end

    def left_insert(another_one)
      @left = another_one
      another_one.father = self
    end

    def right_insert(another_one)
      @right = another_one
      another_one.father = self
    end

    def each
      @left.each {|node| yield node } unless @left.nil?
      yield self
      @right.each {|node| yield node } unless @right.nil?
    end

    def elements
      entries.map {|e| e.element }
    end


    def print

    end

    #protected :insert_into

    #def insert(another_one)
    #  case @element <=> another_one.element
    #    when 1
    #      insert_into(:left, another_one)
    #    when 0
    #      @count += 1
    #    when -1
    #      insert_into(:right, another_one)
    #  end
    #end

    #def insert_into(destination, another_one)
    #  var = destination.to_s
    #  eval(%Q{
    #    if @#{var}.nil?
    #      @#{var} = another_one
    #    else
    #      @#{var}.insert(another_one)
    #    end
    #  })
    #end

    #def count_all
    #  self.map { |node| node.count }.reduce(:+)
    #end
  end
end