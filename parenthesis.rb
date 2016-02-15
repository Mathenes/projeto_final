#encoding: UTF-8
class Parenthesis

  attr_accessor :level
  attr_reader :value

  VALUES = {open: '(', close: ')'}

  def initialize(valor)
    @value = valor
  end

  def type
    VALUES.key @value
  end

  def is_open_parenthesis?
    @value.eql? VALUES[:open]
  end

  def is_close_parenthesis?
    @value.eql? VALUES[:close]
  end

  def to_s
    "Parenthesis, Type: #{type}, Level: #{@level}"
  end

end