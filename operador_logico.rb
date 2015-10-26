#encoding: UTF-8
class OperadorLogico

  attr_accessor :prioridade_parentese
  attr_reader :valor

  VALORES = {negacao: '˜', conjuncao: '&', disjuncao: '|', implicacao: '->'}
  REGEX = /&|\||->|-|>/
  REGEX_UNARIO = /~/

  def initialize(valor,prioridade_parentese)
    @valor = valor
    @prioridade_parentese = prioridade_parentese
  end

  def tipo
    VALORES.key @valor
  end

  def is_negacao?
    @valor.eql? VALORES[:negacao]
  end

  def to_s
    "Operador Lógico, Tipo: #{tipo}, Prioridade: #{prioridade_parentese}"
  end

end