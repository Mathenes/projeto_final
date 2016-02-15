#encoding: UTF-8
class Proposition

  attr_accessor :valor

  REGEX = /^(\*)*[A-z]+[0-9]*$/
  START_OF_NEW_SYMBOL = "*"
  NEW_SYMBOL_DEFAULT = "t"

  def initialize(valor)
    @value = valor
  end

  def to_s
    "Proposição, Valor: #{value}"
  end

end