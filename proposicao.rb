#encoding: UTF-8
class Proposicao

  attr_accessor :valor, :prioridade_parentese
  REGEX = /[A-z]+/

  def initialize(valor,prioridade_parentese)
    @valor = valor
    @prioridade_parentese = prioridade_parentese
  end

  def to_s
    "Proposição, Valor: #{valor}, Prioridade: #{prioridade_parentese}"
  end

end