class Constant
  attr_accessor :prioridade_parentese
  attr_reader :valor

  VALORES = {bottom: '0', up: '1'}
  REGEX = /0|1/

  def initialize(valor,prioridade_parentese)
    @valor = valor
    @prioridade_parentese = prioridade_parentese
  end

  def tipo
    VALORES.key @valor
  end

  def is_up?
    @valor.eql? VALORES[:up]
  end

  def is_bottom?
    @valor.eql? VALORES[:bottom]
  end

  def to_s
    "#{self.name}, Tipo: #{tipo}, Prioridade: #{prioridade_parentese}"
  end
end