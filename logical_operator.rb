#encoding: UTF-8
class LogicalOperator

  attr_reader :value

  VALUES = {negation: '~', conjunction: '&', disjunction: '|', implication: '->'}
  REGEX = /^&$|^\|$|^->$|^-$|^>$/
  REGEX_UNARY = /~/

  def initialize(value=nil)
    if value.instance_of? LogicalOperator
      initialize_with_instance(value)
    else
      @value = value
    end
  end

  def initialize_with_instance(operator)
    @value = String.new(operator.value)
  end

  def type
    VALUES.key @value
  end

  def is_negation?
    @value.eql? VALUES[:negation]
  end

  def is_conjunction?
    @value.eql? VALUES[:conjunction]
  end

  def is_disjunction?
    @value.eql? VALUES[:disjunction]
  end

  def is_implication?
    @value.eql? VALUES[:implication]
  end

  def to_s
    "Logical Operator, Type: #{type}"
  end

end