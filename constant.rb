class Constant
  attr_reader :value

  VALUES = {bottom: '0', up: '1'}
  REGEX = /0|1/

  def initialize(value)
    @value = value
  end

  def tipo
    VALUES.key @value
  end

  def is_up?
    @value.eql? VALUES[:up]
  end

  def is_bottom?
    @value.eql? VALUES[:bottom]
  end

  def to_s
    "Constant, Tipo: #{tipo}"
  end
end