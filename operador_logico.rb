#encoding: UTF-8
class OperadorLogico

  attr_accessor :prioridade_parentese
  attr_reader :valor

  VALORES = {negacao: '~', conjuncao: '&', disjuncao: '|', implicacao: '->'}
  REGEX = /^&$|^\|$|^->$|^-$|^>$/
  REGEX_UNARIO = /~/

  def initialize(valor=nil,prioridade_parentese=nil)
    if valor.instance_of? OperadorLogico
      initialize_with_instance(valor)
    else
      @valor = valor
      @prioridade_parentese = prioridade_parentese
    end
  end

  def initialize_with_instance(operator)
    @valor = String.new(operator.valor)
    @prioridade_parentese = operator.prioridade_parentese
  end

  def tipo
    VALORES.key @valor
  end

  def is_negation?
    @valor.eql? VALORES[:negacao]
  end

  def is_conjunction?
    @valor.eql? VALORES[:conjuncao]
  end

  def is_disjunction?
    @valor.eql? VALORES[:disjuncao]
  end

  def is_implication?
    @valor.eql? VALORES[:implicacao]
  end

  def to_s
    "Operador Lógico, Tipo: #{tipo}, Prioridade: #{prioridade_parentese}"
  end

end