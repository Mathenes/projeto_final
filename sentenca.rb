class Sentenca
  require './proposicao.rb'
  require './operador_logico.rb'
  require './parentese.rb'
  require './constant.rb'
  require 'pry'

  attr_accessor :pai, :bruta, :classificada, :right_sentence, :left_sentence, :operator, :nivel
  #attr_reader :bruta, :classificada, :right_sentence, :left_sentence, :operator, :nivel

  @@new_symbol_count = 0


  def initialize(sentence=nil,father=nil,level=0)
    if sentence == nil
      @nivel = 0
      @bruta = ""
      @classificada = []
    elsif sentence.instance_of? Sentenca
      initialize_with_instance(sentence,father)
    else
      @nivel = (level == 0) ? level + 1 : level
      @bruta = sentence.strip.delete(" ")
      classificar_sentenca
      agrupar if level == 0
    end
  end

  def initialize_with_instance(sentence,father)
    @pai = sentence.pai.nil? ? nil : father
    @bruta = String.new(sentence.bruta)
    @classificada = Array.new(sentence.classificada)
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentenca.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentenca.new(sentence.left_sentence,self)
    @operator = sentence.operator.nil? ? nil : OperadorLogico.new(sentence.operator)
    @nivel = sentence.nivel
  end

  def each(&block)
    bruta_antiga = self.bruta
    yield self unless self.nil?
    self.left_sentence.each{|el|block.call el} if self.left_sentence
    while not bruta_antiga.eql? self.bruta and not bruta_antiga.nil?
      bruta_antiga = self.bruta
      yield self unless self.nil?
    end
    self.right_sentence.each{|el|block.call el} if self.right_sentence and not @operator.is_negation?
    while not bruta_antiga.eql? self.bruta and not bruta_antiga.nil?
      bruta_antiga = self.bruta
      yield self unless self.nil?
    end
  end

  def left_son?
    if @pai
      return Sentenca.equals?(@pai.left_sentence, self)
    else
      return false
    end
  end

  def right_son?
    if @pai
      return Sentenca.equals?(@pai.right_sentence, self)
    else
      return false
    end
  end

  def delete
    if self.pai
      if self.left_son?
        self.pai.copy(self.pai.right_sentence)
        self.pai.update
      elsif self.right_son?
        self.pai.copy(self.pai.left_sentence)
        self.pai.update
      end
      return true
    else
      return false
    end
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
      @bruta = String.new(sentence.bruta)
    end
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentenca.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentenca.new(sentence.left_sentence,self)
    #@left_sentence.pai = self if @left_sentence
    #@right_sentence.pai = self if @right_sentence
    @operator = sentence.operator.nil? ? nil : OperadorLogico.new(sentence.operator)
  end

  #TODO: VERIFICAR SE É POSSÍVEL UTILIZAR !IS_LITERAL? (DAVA PROBLEMA POIS UM LITERAL NEGADO TB É UM LITERAL E DEVE SER ATUALIZADO)
  def update_bruta_and_classificada
    unless @left_sentence.nil? and @right_sentence.nil?
      @bruta = "("+(@left_sentence.nil? ? "":@left_sentence.bruta) + (@operator.nil? ? "":@operator.valor) + (@right_sentence.nil? ? "":@right_sentence.bruta)+")"
    end
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

  #negação é um literal com filho da direita, por isso ao atualizar sua bruta, devemos olhar seu filho da direita
  def update(bruta=nil)
    unless bruta
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

  #---------------------------------------------------------------------------------------------------------------------
  # Método que simplifica as sentenças de acordo com as regras
  # contidas no paper que é base para este projeto;

  def simplification
    changed = true
    while changed
      changed = false
      unless @operator.nil?
        old_left = ( @left_sentence ? Sentenca.new(@left_sentence) : nil )
        old_right = ( @right_sentence ? Sentenca.new(@right_sentence) : nil )
                 #binding.pry
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
            elsif is_not_bottom?
              update(Constant::VALORES[:up])
            elsif is_not_up?
              update(Constant::VALORES[:bottom])
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

  def is_bottom?
    return (is_constant? and @classificada.first.is_bottom?)
  end

  def is_up?
    return (is_constant? and @classificada.first.is_up?)
  end

  def is_not_bottom?
    if (@operator and @operator.is_negation?)
      @right_sentence.is_not_bottom?
    else
      return (is_bottom? and @pai and @pai.operator and @pai.operator.is_negation?)
    end
  end

  def is_not_up?
    if (@operator and @operator.is_negation?)
      @right_sentence.is_not_up?
    else
      return (is_up? and @pai and @pai.operator and @pai.operator.is_negation?)
    end
  end


  #----------------TRANSFORMATION FUNCTION INTO APNF------------------

  def transformation_into_apnf
    self.simplification
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
          @right_sentence.transformation_into_apnf if @right_sentence
        end
      else
        case @operator.tipo
          when :implicacao
            @operator = OperadorLogico.new(OperadorLogico::VALORES[:disjuncao], @operator.prioridade_parentese)
            @left_sentence = @left_sentence.negated
            @left_sentence.pai = self
            update
        end
        @left_sentence.transformation_into_apnf if @left_sentence
        @right_sentence.transformation_into_apnf if @right_sentence
      end

      unless Sentenca.equals?(old_left, @left_sentence) and Sentenca.equals?(old_right, @right_sentence)
        update
      end
    end
    self
  end

  #--------------------------------------------------------------------
  #---------------------TRANSFORMATION INTO DSNF-----------------------
  def transformation_into_dsnf
    negated_sentence_in_apnf = self.negated.transformation_into_apnf
    puts "###### APNF ######"
    puts "#{negated_sentence_in_apnf.bruta}"
    initial = [Sentenca.new(generate_new_symbol)]
    first_element = Sentenca.generate_implication_between(Sentenca.new(initial.first), Sentenca.new(negated_sentence_in_apnf))
    universe = [first_element]

    #RULES 1 AND 2 OF THE PAPER
    first_step_dsnf(universe)
    #RULE 6 OF THE PAPER
    second_step_dsnf(universe)

    universe.each do |el|
      el.simplification
    end

    return {:I => initial, :U => universe}
  end
  #--------------------------------------------------------------------

  def self.opposites_literals?(sentence1, sentence2)
    if sentence1.is_literal? and sentence2.is_literal?
      if sentence1.operator and sentence1.operator.is_negation? and not sentence2.operator
        if sentence1.right_sentence.bruta.eql? sentence2.bruta
          return true
        end
      elsif sentence2.operator and sentence2.operator.is_negation? and not sentence1.operator
        if sentence2.right_sentence.bruta.eql? sentence1.bruta
          return true
        end
      end
    end
    false
  end

  def self.same_literals?(sentence1, sentence2)
    return sentence1.bruta.eql? sentence2.bruta
  end
  #----------------------------------------------------PROTECTED--------------------------------------------------------

  protected

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
        if el.operator.is_implication?
          left_symbol = Sentenca.new(el.left_sentence).negated                  #pega o ~t
          disjunction_of_literals_or_literal = el.right_sentence                #pega a disjuncao de literais ou o literal
          universe.push Sentenca.generate_disjunction_between(left_symbol, disjunction_of_literals_or_literal)
          universe.delete_at(index)
          is_done = false
        end
      end
    end
  end

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
        #Exemplo: #(~(a & b)) ou (~(~a))
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




  ##Aplication of the resolution rules
  ##PRIMEIRA RESOLUÇÃO
  #def self.resolution(ires, ures)
  #  ires_local = [Sentenca.new(ires.first)]
  #  ures_local = []
  #  ures.each{|el|ures_local.push Sentenca.new(el)}
  #  i,j = 0,1
  #  is_done = false
  #
  #  puts "--------------------------------------------------------"
  #  ires_local.map{|i| puts "#{i.bruta}     [I]"}
  #  ures_local.map{|i| puts "#{i.bruta}     [U]"}
  #  puts "--------------------------------------------------------"
  #
  #  if ures.count == 1
  #    if Sentenca.comparison(ires_local.first,ures_local.first).nil?
  #      ures_local = nil
  #    end
  #  else
  #    while not is_done and i <= ures_local.count-1
  #      while not is_done and j <= ures_local.count-1
  #
  #        if ures_local[i].is_literal?
  #          puts "###### PAR ######"
  #          puts "#{ires_local.first.bruta}  [I]"
  #          puts "#{ures_local[j].bruta}  [U]"
  #          if Sentenca.comparison(ires_local.first,ures_local[i]).nil?
  #            is_done = true
  #            ures_local = nil
  #          end
  #        elsif ures_local[j].is_literal?
  #          puts "###### PAR ######"
  #          puts "#{ires_local.first.bruta}  [I]"
  #          puts "#{ures_local[j].bruta}  [U]"
  #          if Sentenca.comparison(ires_local.first,ures_local[j]).nil?
  #            is_done = true
  #            ures_local = nil
  #          end
  #        else
  #          puts "###### PAR ######"
  #          puts "#{ures_local[i].bruta}  [U]"
  #          puts "#{ures_local[j].bruta}  [U]"
  #          ures_local.push Sentenca.comparison(ures_local[i],ures_local[j])
  #          ures_local[i],ures_local[j] = nil, nil
  #          ures_local = ures_local.compact
  #        end
  #
  #        if not is_done
  #          if Sentenca.resolution(ires_local,ures_local)
  #            is_done = true
  #            ures_local = nil
  #          else
  #            puts "###### BACK ######"
  #            ures_local = []
  #            ures.each{|el|ures_local.push Sentenca.new(el)}
  #
  #            puts "---------------VOLTOU PARA A CONFIGURAÇÃO---------------"
  #            ires_local.map{|i| puts "#{i.bruta}     [I]"}
  #            ures_local.map{|i| puts "#{i.bruta}     [U]"}
  #            puts "--------------------------------------------------------"
  #            j = j.next
  #          end
  #        end
  #      end
  #      i = i.next
  #      j = i + 1
  #    end
  #  end
  #  return ures_local.nil?
  #end
end