#encoding: UTF-8
class Parentese

  attr_accessor :prioridade
  attr_reader :valor

  VALORES = {abre: '(', fecha: ')'}

  def initialize(valor)
    @valor = valor
  end

  def tipo
    VALORES.key @valor
  end

  def is_abre_parentese?
    @valor.eql? VALORES[:abre]
  end

  def is_fecha_parentese?
    @valor.eql? VALORES[:fecha]
  end

  def to_s
    "Parêntese, Tipo: #{tipo}, Prioridade: #{prioridade}"
  end

end