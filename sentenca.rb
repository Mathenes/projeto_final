class Sentenca
  require './proposicao.rb'
  require './operador_logico.rb'
  require './parentese.rb'
  require './constant.rb'
  require 'pry'

  attr_accessor :pai, :bruta, :classificada, :right_sentence, :left_sentence, :operator, :nivel
  #attr_reader :bruta, :classificada, :right_sentence, :left_sentence, :operator, :nivel

  @@new_symbol_count = 0


  def initialize(sentence=nil,level=0)
    if sentence == nil
      @nivel = 0
      @bruta = ""
    elsif sentence.instance_of? Sentenca
      initialize_with_instance(sentence)
    else
      @nivel = (level == 0) ? level + 1 : level
      @bruta = sentence.strip.delete(" ")
      classificar_sentenca
      agrupar if level == 0
    end
  end

  def initialize_with_instance(sentence)
    @pai = sentence.pai
    @bruta = sentence.bruta
    @classificada = sentence.classificada
    @right_sentence = sentence.right_sentence
    @left_sentence = sentence.left_sentence
    @operator = sentence.operator
    @nivel = sentence.nivel
  end

  def to_s
    bruta = "Bruta: #{@bruta}"
    puts bruta
    puts
    pai = "Pai: #{@pai.bruta if @pai}"
    puts pai
    puts
    left_sentence = "Left: #{@left_sentence.bruta if @left_sentence}"
    puts left_sentence
    puts
    operator = "Operator: #{@operator.valor if @operator}"
    puts operator
    puts
    right_sentence = "Right: #{@right_sentence.bruta if @right_sentence}"
    puts right_sentence
    puts
    level = "Level: #{@nivel}"
    puts level
    puts
  end

  def is_literal?
    if @operator and @operator.is_negation?
      @right_sentence.is_literal?
    else
      @left_sentence.nil? and @right_sentence.nil?
    end
  end

  def is_constant?
    @classificada.first.instance_of? Constant
  end


  #http://codereview.stackexchange.com/questions/6774/check-if-a-binary-tree-is-a-subtree-of-another-tree
  def self.equals?(sentence1, sentence2)
    return true if (sentence1 == sentence2)
    return false if (sentence1 == nil || sentence2 == nil)
    return false if (sentence1.bruta != sentence2.bruta)
    return Sentenca.equals?(sentence1.left_sentence, sentence2.left_sentence) && Sentenca.equals?(sentence1.right_sentence, sentence2.right_sentence)
  end

  def self.generate_implication_between(sentence1, sentence2)
    aux = Sentenca.new
    aux.left_sentence = sentence1
    aux.right_sentence = sentence2
    aux.left_sentence.pai, aux.right_sentence.pai = aux, aux
    aux.nivel = 1
    aux.operator = OperadorLogico.new(OperadorLogico::VALORES[:implicacao],aux.nivel)
    aux.update
    aux
  end

  def self.generate_disjunction_between(sentence1, sentence2)
    aux = Sentenca.new
    aux.left_sentence = sentence1
    aux.right_sentence = sentence2
    aux.left_sentence.pai, aux.right_sentence.pai = aux, aux
    aux.nivel = 1
    aux.operator = OperadorLogico.new(OperadorLogico::VALORES[:disjuncao],aux.nivel)
    aux.update
    aux
  end

  def propositional_symbols
    symbols = []
    @classificada.each do |el|
      symbols.push el if el.instance_of? Proposicao
    end
    symbols
  end

  #TODO: Verificar se essa é a melhor forma para negar uma sentença. Pelo menos é a forma mais rápida, pois a outra
  #forma envolveria atualizar a bruta com uma negação e a partir daí chamar a função agrupar. Mas isso tem um custo
  #de processamento bem maior, porque teria que estar sempre chamando a função agrupar - que é uma função recursiva.
  def negated
    aux = Sentenca.new
    aux.operator = OperadorLogico.new(OperadorLogico::VALORES[:negacao], self.nivel)
    aux.nivel = self.nivel
    aux.right_sentence = Sentenca.new(self)
    aux.right_sentence.pai = aux
    aux.bruta = "(#{OperadorLogico::VALORES[:negacao]}#{self.bruta})"
    aux.left_sentence.update_level if aux.left_sentence
    aux.right_sentence.update_level if aux.right_sentence
    aux.classificar_sentenca
    aux
  end

  def copy(sentence)
    if sentence.is_literal? or sentence.is_constant?
      @bruta = sentence.bruta
    end
    @right_sentence = sentence.right_sentence
    @left_sentence = sentence.left_sentence
    @left_sentence.pai = self if @left_sentence
    @right_sentence.pai = self if @right_sentence
    @operator = sentence.operator
  end

  def update_bruta_and_classificada
    @bruta = "("+(@left_sentence.nil? ? "":@left_sentence.bruta) + (@operator.nil? ? "":@operator.valor) + (@right_sentence.nil? ? "":@right_sentence.bruta)+")"
    classificar_sentenca
  end

  def update_level
    if is_literal?
      @nivel = @pai.nivel
    else
      @nivel = @pai.nivel + 1
      @left_sentence.update_level unless @left_sentence.nil?
      @right_sentence.update_level unless @right_sentence.nil?
    end
  end

  def update_classificada
    classificar_sentenca
    @left_sentence.update_classificada unless @left_sentence.nil?
    @right_sentence.update_classificada unless @right_sentence.nil?
  end

  def update(bruta=nil)
    unless bruta or is_literal?
      update_bruta_and_classificada
      @left_sentence.update_level unless @left_sentence.nil?
      @right_sentence.update_level unless @right_sentence.nil?
      @left_sentence.update_classificada unless @left_sentence.nil?
      @right_sentence.update_classificada unless @right_sentence.nil?
    else
      @bruta = bruta if bruta
      classificar_sentenca
    end
  end


  # Método que simplifica as sentenças de acordo com as regras
  # contidas no paper que é base para este projeto;

  def simplification
    changed = true
    while changed
      changed = false
      unless @operator.nil?
        old_left = ( @left_sentence ? Sentenca.new(@left_sentence) : nil )
        old_right = ( @right_sentence ? Sentenca.new(@right_sentence) : nil )

        case @operator.tipo
          when :conjuncao
            if is_formula_and_formula?
              copy @left_sentence
              update
            elsif is_formula_and_not_formula?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              @bruta = Constant::VALORES[:bottom]
              classificar_sentenca
            elsif is_formula_and_up?
              if @left_sentence.is_constant?
                copy @right_sentence
              else
                copy @left_sentence
              end
              update
            elsif is_formula_and_bottom?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALORES[:bottom])
            end
          when :disjuncao
            if is_formula_or_formula?
              copy @left_sentence
              update
            elsif is_formula_or_not_formula?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALORES[:up])
            elsif is_formula_or_up?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALORES[:up])
            elsif is_formula_or_bottom?
              if @left_sentence.is_constant?
                copy @right_sentence
              else
                copy @left_sentence
              end
              update
            end
          when :negacao
            if is_double_negation?
              copy @right_sentence.right_sentence
              update
            end
        end

        @left_sentence.simplification unless @left_sentence.nil?
        @right_sentence.simplification unless @right_sentence.nil?

        unless Sentenca.equals?(old_left, @left_sentence) and Sentenca.equals?(old_right, @right_sentence)
          changed = true
          update
        end
      end
    end
    self
  end

  #--------------- simplifications ------------------------

  # φ|φ
  def is_formula_or_formula?
    if @operator.is_disjunction?
      if Sentenca.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # φ&φ
  def is_formula_and_formula?
    if @operator.is_conjunction?
      if Sentenca.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # φ | (~φ)
  def is_formula_or_not_formula?
    if @operator.is_disjunction?
      if @right_sentence.operator and @right_sentence.operator.is_negation?
        if Sentenca.equals?(@left_sentence,@right_sentence.right_sentence)
          return true
        end
      elsif @left_sentence.operator and @left_sentence.operator.is_negation?
        if Sentenca.equals?(@left_sentence.right_sentence,@right_sentence)
          return true
        end
      end
    end
    false
  end

  # φ & (~φ)
  def is_formula_and_not_formula?
    if @operator.is_conjunction?
      if @right_sentence.operator and @right_sentence.operator.is_negation?
        if Sentenca.equals?(@left_sentence,@right_sentence.right_sentence)
          return true
        end
      elsif @left_sentence.operator and @left_sentence.operator.is_negation?
        if Sentenca.equals?(@left_sentence.right_sentence,@right_sentence)
          return true
        end
      end
    end
    false
  end

  # φ & ⊤
  def is_formula_and_up?
    if @operator.is_conjunction?
      if @left_sentence and @right_sentence.is_constant?
        return @right_sentence.classificada.first.is_up?
      elsif @left_sentence.is_constant? and @right_sentence
        return @left_sentence.classificada.first.is_up?
      end
    end
    false
  end

  # φ & ⊥
  def is_formula_and_bottom?
    if @operator.is_conjunction?
      if @left_sentence and @right_sentence.is_constant?
        return @right_sentence.classificada.first.is_bottom?
      elsif @left_sentence.is_constant? and @right_sentence
        return @left_sentence.classificada.first.is_bottom?
      end
    end
    false
  end

  # φ & ⊤
  def is_formula_or_up?
    if @operator.is_disjunction?
      if @left_sentence and @right_sentence.is_constant?
        return @right_sentence.classificada.first.is_up?
      elsif @left_sentence.is_constant? and @right_sentence
        return @left_sentence.classificada.first.is_up?
      end
    end
    false
  end

  # φ & ⊥
  def is_formula_or_bottom?
    if @operator.is_disjunction?
      if @left_sentence and @right_sentence.is_constant?
        return @right_sentence.classificada.first.is_bottom?
      elsif @left_sentence.is_constant? and @right_sentence
        return @left_sentence.classificada.first.is_bottom?
      end
    end
    false
  end

  # (~(~a))
  def is_double_negation?
    if @operator.is_negation?
      if @right_sentence.operator and @right_sentence.operator.is_negation?
        return true
      end
    end
    false
  end


  #----------------TRANSFORMATION FUNCTION INTO APNF------------------

  def transformation_into_apnf
    unless @operator.nil?
      old_left = ( @left_sentence ? Sentenca.new(@left_sentence) : nil )
      old_right = ( @right_sentence ? Sentenca.new(@right_sentence) : nil )

      if @operator.is_negation?
        unless @right_sentence.operator.nil?
          case @right_sentence.operator.tipo
            when :implicacao
              copy @right_sentence
              @operator = OperadorLogico.new(OperadorLogico::VALORES[:conjuncao], @operator.prioridade_parentese)
              @right_sentence = @right_sentence.negated
              @right_sentence.pai = self
              update
            when :conjuncao
              copy @right_sentence
              @operator = OperadorLogico.new(OperadorLogico::VALORES[:disjuncao], @operator.prioridade_parentese)
              @left_sentence = @left_sentence.negated
              @right_sentence = @right_sentence.negated
              @right_sentence.pai,@left_sentence.pai  = self,self
              update
            when :disjuncao
              copy @right_sentence
              @operator = OperadorLogico.new(OperadorLogico::VALORES[:conjuncao], @operator.prioridade_parentese)
              @left_sentence = @left_sentence.negated
              @right_sentence = @right_sentence.negated
              @right_sentence.pai,@left_sentence.pai  = self,self
              update
          end
          @left_sentence.transformation_into_apnf if @left_sentence
          @right_sentence.transformation_into_apnf
        end
      else
        case @operator.tipo
          when :implicacao
            @operator = OperadorLogico.new(OperadorLogico::VALORES[:disjuncao], @operator.prioridade_parentese)
            @left_sentence = @left_sentence.negated
            @left_sentence.pai = self
            update
        end
        @left_sentence.transformation_into_apnf
        @right_sentence.transformation_into_apnf
      end

      unless Sentenca.equals?(old_left, @left_sentence) and Sentenca.equals?(old_right, @right_sentence)
        update
      end
    end
    self
  end

  #-------------------------------------------------------------------
  #---------------------TRANSFORMATION INTO DSNF-----------------------
  def transformation_into_dsnf
    initial = [Sentenca.new(generate_new_symbol)]
    first_element = Sentenca.generate_implication_between(initial.first, Sentenca.new(self.transformation_into_apnf))
    universe = [first_element]

    #RULES 1 AND 2 OF THE PAPER
    first_step_dsnf(universe)
    #RULE 6 OF THE PAPER
    second_step_dsnf(universe)

    return {:I => initial, :U => universe}
  end

  def first_step_dsnf(universe)
    is_done = false
    while not is_done
      is_done = true
      universe.each_with_index do |el, index|
        if el.right_sentence.operator
          case el.right_sentence.operator.tipo
            #REGRA 1
            when :conjuncao
              left_symbol = Sentenca.new(el.left_sentence)              #pega o t
              formula1 = el.right_sentence.left_sentence                #pega o φ1
              formula2 = el.right_sentence.right_sentence               #pega o φ2
              universe.push Sentenca.generate_implication_between(left_symbol, formula1)
              left_symbol = Sentenca.new(el.left_sentence)              #cria outro t em outra posição da memória
              universe.push Sentenca.generate_implication_between(left_symbol, formula2)
              universe.delete_at(index)                                 #tira a sentença do conjunto
              is_done = false

            #REGRA 2
            when :disjuncao
              formula = el.right_sentence
              unless formula.right_sentence.is_literal?
                left_symbol = Sentenca.new(el.left_sentence)            #pega o t
                new_symbol = Sentenca.new(generate_new_symbol)                        #gera novo simbolo t1
                formula1 = el.right_sentence.left_sentence              #pega o φ1
                formula2 = el.right_sentence.right_sentence             #pega o φ2
                aux = Sentenca.generate_disjunction_between(formula1, new_symbol) #gera a disjuncao entre φ1 e o novo simbolo
                universe.push Sentenca.generate_implication_between(left_symbol, aux)
                universe.push Sentenca.generate_implication_between(new_symbol, formula2)
                universe.delete_at(index)
                is_done = false
              else
                unless formula.left_sentence.is_literal?
                  left_symbol = Sentenca.new(el.left_sentence)            #pega o t
                  new_symbol = Sentenca.new(generate_new_symbol)                        #gera novo simbolo t1
                  formula1 = el.right_sentence.right_sentence             #pega o φ2 (neste caso ele é um literal)
                  formula2 = el.right_sentence.left_sentence              #pega o φ1
                  aux = Sentenca.generate_disjunction_between(formula1, new_symbol) #gera a disjuncao entre φ1 e o novo simbolo
                  universe.push Sentenca.generate_implication_between(left_symbol, aux)
                  universe.push Sentenca.generate_implication_between(new_symbol, formula2)
                  universe.delete_at(index)
                  is_done = false
                end
              end
          end
        end
      end
    end
  end

  def second_step_dsnf(universe)
    is_done = false
    while not is_done
      is_done = true
      universe.each_with_index do |el, index|
        if el.operator.is_implication? and el.right_sentence.operator
          case el.right_sentence.operator.tipo
            #REGRA 6
            when :disjuncao
              left_symbol = Sentenca.new(el.left_sentence).negated                  #pega o ~t
              disjunction_of_literals = el.right_sentence                           #pega a disjuncao de literais
              universe.push Sentenca.generate_disjunction_between(left_symbol, disjunction_of_literals)
              universe.delete_at(index)
              is_done = false
          end
        end
      end
    end
  end
  #-------------------------------------------------------------------

  protected

  def generate_new_symbol
    new_symbol = Proposicao::START_OF_NEW_SYMBOL + Proposicao::NEW_SYMBOL_DEFAULT + @@new_symbol_count.to_s
    @@new_symbol_count = @@new_symbol_count.next
    new_symbol
  end

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

        when ( Proposicao::START_OF_NEW_SYMBOL.eql? char )
          buffer.concat char

        when ( Proposicao::REGEX.match "#{buffer}#{char}" )
          look_ahead(Proposicao, index, char, buffer, sentenca_classificada, nivel_parentese)

        when ( Constant::REGEX.match char )
          sentenca_classificada.push Constant.new(char,nivel_parentese)
      end
    end

    @classificada = sentenca_classificada
  end

  def look_ahead(kclass, index, char, buffer, sentenca_classificada, nivel_parentese)
    if @bruta[index + 1] and kclass::REGEX.match( "#{buffer}#{char}#{@bruta[index + 1]}" )
      buffer.concat char
    else
      sentenca_classificada.push kclass.new(buffer+char,nivel_parentese)
      buffer.clear
    end
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
      @left_sentence.pai, @right_sentence.pai = self, self

    elsif negated_sentence(index)
      @operator = @classificada[index]
      #Exemplo: (~a) ou (~1)
      if @classificada[index+1].instance_of?(Proposicao) or @classificada[index+1].instance_of?(Constant)
        @right_sentence = Sentenca.new(@classificada[index+1].valor,@nivel)
        @right_sentence.pai = self
      else
        #Exemplo: #(~(a & b))
        index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
        aux = @classificada[index+1..index_closed_parenthesis].map{|el|el.valor}*""
        @right_sentence = Sentenca.new(aux,@nivel+1).agrupar
        @right_sentence.pai = self
      end

    elsif left_derivative(index)
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @left_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @operator = @classificada[index_closed_parenthesis + 1]
      @right_sentence = Sentenca.new(@classificada[index_closed_parenthesis + 2].valor,@nivel)
      @left_sentence.pai, @right_sentence.pai = self, self

    elsif right_derivative(index)
      @left_sentence = Sentenca.new(@classificada[index].valor,@nivel)
      @operator = @classificada[index + 1]
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1,index)
      aux = @classificada[(index+2)..index_closed_parenthesis].map{|el|el.valor}*""
      @right_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @left_sentence.pai, @right_sentence.pai = self, self

    elsif both_derivative(index)
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @left_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @operator = @classificada[index_closed_parenthesis + 1]
      index = index_closed_parenthesis + 2
      index_closed_parenthesis = index_closed_parenthesis(@nivel+1,index)
      aux = @classificada[index..index_closed_parenthesis].map{|el|el.valor}*""
      @right_sentence = Sentenca.new(aux,@nivel+1).agrupar
      @left_sentence.pai, @right_sentence.pai = self, self
    end
    self
  end

  #Exemplo: (a&b)
  def primitive_sentence(index)
    if @classificada[index].instance_of? Proposicao or @classificada[index].instance_of? Constant
      if @classificada[index + 1].instance_of? OperadorLogico
        if @classificada[index + 2].instance_of? Proposicao or @classificada[index + 2].instance_of? Constant
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
        if @classificada[index+2].instance_of? Proposicao or @classificada[index+2].instance_of? Constant
          return true
        end
      end
    end
    false
  end

  #Exemplo: a->(b&c)
  def right_derivative(index)
    if @classificada[index].instance_of? Proposicao or @classificada[index].instance_of? Constant
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


  #TODO: melhorar negated_sentence

  #Exemplo: (~(a&b)) ou (~a)
  def negated_sentence(index)
    if @classificada[index] and OperadorLogico::REGEX_UNARIO.match @classificada[index].valor
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