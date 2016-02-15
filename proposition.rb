#encoding: UTF-8
class Proposition

  attr_accessor :value

  REGEX = /^(\*)*[A-z]+[0-9]*$/
  START_OF_NEW_SYMBOL = "*"
  NEW_SYMBOL_DEFAULT = "t"

  def initialize(value)
    @value = value
  end

  def to_s
    "Proposition, Value: #{@value}"
  end

end