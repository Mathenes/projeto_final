class Sentenca
  require './proposicao.rb'
  require './operador_logico.rb'
  require './parentese.rb'
  require 'pry'

  attr_accessor :pai
  attr_reader :bruta, :classificada, :right_sentence, :left_sentence, :operator, :nivel

  def initialize(sentenca,nivel=0)
    @nivel = (nivel == 0) ? nivel + 1 : nivel
    @bruta = sentenca.strip.delete(" ")
    classificar_sentenca
    agrupar if nivel == 0
  end

  def add_sentences_and_operator(left_sentence,operator,right_sentence)

  end

  #(a & b)
  #(~(a & b))
  #(~a)
  #( (a & b) -> ( c | d ) )
  #( (a -> (b & c)) -> d )
  #( d -> (a -> (b & c)) )
  # ( (((a&b)|(c&d)) -> ((f&g)|(g&h))) -> (x&y) )
  # ( ( ((a&b)|(c&d)) -> (~((f&g)|(g&h))) ) -> (x&y) )

  def agrupar
    index = 1
    if primitive_sentence(index)
      @left_sentence = Sentenca.new(@classificada[index].valor,@nivel)
      @operator = @classificada[index + 1]
      @right_sentence = Sentenca.new(@classificada[index + 2].valor,@nivel)

    elsif negated_sentence(index)
      @operator = @classificada[index]
      #Exemplo: #(~a)
      if @classificada[index+1].instance_of?(Proposicao)
        @right_sentence = Sentenca.new(@classificada[index+1].valor,@nivel)
      else
      #Exemplo: #(~(a & b))
        index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
        aux = @classificada[index+1..index_closed_parenthesis].map{|el|el.valor}*""
        @right_sentence = Sentenca.new(aux,@nivel+1).agrupar
      end

    elsif left_derivative(index)
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @left_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @operator = @classificada[index_closed_parenthesis + 1]
      @right_sentence = Sentenca.new(@classificada[index_closed_parenthesis + 2].valor,@nivel)

    elsif right_derivative(index)
      @left_sentence = Sentenca.new(@classificada[index].valor,@nivel)
      @operator = @classificada[index + 1]
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1,index)
      aux = @classificada[(index+2)..index_closed_parenthesis].map{|el|el.valor}*""
      @right_sentence = Sentenca.new(aux,@nivel+1).agrupar

    else
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @left_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @operator = @classificada[index_closed_parenthesis + 1]
      index = index_closed_parenthesis + 2
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1,index)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @right_sentence = Sentenca.new(aux,@nivel+1).agrupar
    end
    self
  end

  private
  def classificar_sentenca
    sentenca_classificada = []
    buffer = ""
    nivel_parentese = @nivel

    @bruta.chars.each_with_index do |char, index|
      case
        when ( Parentese::VALORES.has_value? char )
          parentese = Parentese.new(char)
          if parentese.is_abre_parentese?
            nivel_parentese += 1 unless index==0
            parentese.prioridade = nivel_parentese
            sentenca_classificada.push parentese
          else
            parentese.prioridade = nivel_parentese
            sentenca_classificada.push parentese
            nivel_parentese -= 1
          end

        when ( OperadorLogico::REGEX_UNARIO.match char )
          sentenca_classificada.push OperadorLogico.new(char,nivel_parentese)

        when ( OperadorLogico::REGEX.match char )
          look_ahead(OperadorLogico, index, char, buffer, sentenca_classificada, nivel_parentese)

        when ( Proposicao::REGEX.match char )
          look_ahead(Proposicao, index, char, buffer, sentenca_classificada, nivel_parentese)
      end
    end

    @classificada = sentenca_classificada
  end

  def look_ahead(kclass, index, char, buffer, sentenca_classificada, nivel_parentese)
    if kclass::REGEX.match( @bruta[index + 1] )
      buffer.concat char
    else
      sentenca_classificada.push kclass.new(buffer+char,nivel_parentese)
      buffer.clear
    end
  end

  #Exemplo: (a&b)
  def primitive_sentence(index)
    if @classificada[index].instance_of? Proposicao
      if @classificada[index + 1].instance_of? OperadorLogico
        if @classificada[index + 2].instance_of? Proposicao
          return true
        end
      end
    end
    false
  end

  #Exemplo: (a&b)->c
  def left_derivative(index)
    if @classificada[index].instance_of? Parentese
      level = @classificada[index].prioridade
      index = index_closed_parenthesis(level)
      if @classificada[index+1].instance_of? OperadorLogico
        if @classificada[index+2].instance_of? Proposicao
          return true
        end
      end
    end
    false
  end

  #Exemplo: a->(b&c)
  def right_derivative(index)
    if @classificada[index].instance_of? Proposicao
      if @classificada[index+1].instance_of? OperadorLogico
        if @classificada[index+2].instance_of? Parentese
          return true
        end
      end
    end
    false
  end

  #Exemplo: ((a&b)->(c&d))
  def both_derivative(index)
    if @classificada[index].instance_of? Parentese
      level = @classificada[index].prioridade
      index = index_closed_parenthesis(level)
      if @classificada[index+1].instance_of? OperadorLogico
        if @classificada[index+2].instance_of? Parentese
          return true
        end
      end
    end
    false
  end

  #Exemplo: (~(a&b))
  def negated_sentence(index)
    if OperadorLogico::REGEX_UNARIO.match @classificada[index].valor
      return true
    end
    false
  end

  def index_closed_parenthesis(level,index=0)
    if index == 0
      @classificada.find_index {|el| (el.is_fecha_parentese? if el.instance_of? Parentese) and el.prioridade == level}
    else
      aux = Array.new @classificada
      aux.fill(0,0..index).find_index {|el| (el.is_fecha_parentese? if el.instance_of? Parentese) and el.prioridade == level}
    end
  end

end