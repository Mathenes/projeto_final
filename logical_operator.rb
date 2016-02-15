#encoding: UTF-8
class LogicalOperator

  attr_reader :valor

  VALORES = {negacao: '~', conjuncao: '&', disjuncao: '|', implicacao: '->'}
  REGEX = /^&$|^\|$|^->$|^-$|^>$/
  REGEX_UNARIO = /~/

  def initialize(valor=nil)
    if valor.instance_of? LogicalOperator
      initialize_with_instance(valor)
    else
      @value = valor
    end
  end

  def initialize_with_instance(operator)
    @value = String.new(operator.value)
  end

  def tipo
    VALORES.key @value
  end

  def is_negation?
    @value.eql? VALORES[:negacao]
  end

  def is_conjunction?
    @value.eql? VALORES[:conjuncao]
  end

  def is_disjunction?
    @value.eql? VALORES[:disjuncao]
  end

  def is_implication?
    @value.eql? VALORES[:implicacao]
  end

  def to_s
    "Operador Lógico, Tipo: #{tipo}"
  end

end