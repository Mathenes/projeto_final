class Sentence
  require './proposition.rb'
  require './logical_operator.rb'
  require './parenthesis.rb'
  require './constant.rb'
  require 'pry'

  attr_accessor :father, :raw, :classified, :right_sentence, :left_sentence, :operator, :level

  @@new_symbol_count = 0

  def initialize(sentence=nil,father_or_level = 0)
    if sentence == nil
      @level = 0
      @raw = ""
      @classified = []
    elsif sentence.instance_of? Sentence
      father = father_or_level
      initialize_with_instance(sentence,father)
    else
      level = father_or_level
      @level = (level == 0) ? level + 1 : level
      @raw = sentence.strip.delete(" ")
      classify_sentence
      group if level == 0
    end
  end

  def initialize_with_instance(sentence,father)
    @father = sentence.father.nil? ? nil : father
    @raw = String.new(sentence.raw)
    @classified = Array.new(sentence.classified)
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentence.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentence.new(sentence.left_sentence,self)
    @operator = sentence.operator.nil? ? nil : LogicalOperator.new(sentence.operator)
    @level = sentence.level
  end

  def each(&block)
    old_raw = @raw
    yield self unless self.nil?
    self.left_sentence.each{|el|block.call el} if self.left_sentence
    while (not old_raw.eql?(@raw)) && (not old_raw.nil?)
      old_raw = @raw
      yield self unless self.nil?
    end
    self.right_sentence.each{|el|block.call el} if (self.right_sentence) && (not @operator.is_negation?)
    while (not old_raw.eql?(self.raw)) && (not old_raw.nil?)
      old_raw = self.raw
      yield self unless self.nil?
    end
  end

  def left_son?
    if @father
      return Sentence.equals?(@father.left_sentence, self)
    else
      return false
    end
  end

  def right_son?
    if @father
      return Sentence.equals?(@father.right_sentence, self)
    else
      return false
    end
  end

  #only literals are being deleted, so there`s no problem
  def delete
    if self.father
      if self.left_son?
        self.father.copy(self.father.right_sentence)
      elsif self.right_son?
        self.father.copy(self.father.left_sentence)
      end
      aux = self.father
      while aux != nil
        aux.update
        aux = aux.father
      end
      return true
    else
      return false
    end
  end

  def to_s
    raw = "Raw: #{@raw}"
    puts raw
    puts
    father = "Father: #{@father.raw if @father}"
    puts father
    puts
    left_sentence = "Left: #{@left_sentence.raw if @left_sentence}"
    puts left_sentence
    puts
    operator = "Operator: #{@operator.value if @operator}"
    puts operator
    puts
    right_sentence = "Right: #{@right_sentence.raw if @right_sentence}"
    puts right_sentence
    puts
    level = "Level: #{@level}"
    puts level
    puts
  end

  def is_literal?
    if @operator && @operator.is_negation?
      @right_sentence.is_literal?
    else
      @left_sentence.nil? && @right_sentence.nil?
    end
  end

  def is_constant?
    @classified.first.instance_of? Constant
  end


  #http://codereview.stackexchange.com/questions/6774/check-if-a-binary-tree-is-a-subtree-of-another-tree
  def self.equals?(sentence1, sentence2)
    return true if (sentence1 == sentence2)
    return false if (sentence1 == nil || sentence2 == nil)
    return false if (sentence1.raw != sentence2.raw)
    return Sentence.equals?(sentence1.left_sentence, sentence2.left_sentence) && Sentence.equals?(sentence1.right_sentence, sentence2.right_sentence)
  end

  def self.generate_implication_between(sentence1, sentence2)
    aux = Sentence.new
    aux.left_sentence = sentence1
    aux.right_sentence = sentence2
    aux.left_sentence.father, aux.right_sentence.father = aux, aux
    aux.level = 1
    aux.operator = LogicalOperator.new(LogicalOperator::VALUES[:implication])
    aux.update
    aux
  end

  def self.generate_disjunction_between(sentence1, sentence2)
    aux = Sentence.new
    aux.left_sentence = sentence1
    aux.right_sentence = sentence2
    aux.left_sentence.father, aux.right_sentence.father = aux, aux
    aux.level = 1
    aux.operator = LogicalOperator.new(LogicalOperator::VALUES[:disjunction])
    aux.update
    aux
  end

  def propositional_symbols
    symbols = []
    @classified.each do |el|
      symbols.push el if el.instance_of? Proposition
    end
    symbols
  end

  #TODO: Verificar se essa é a melhor forma para negar uma sentença. Pelo menos é a forma mais rápida, pois a outra
  #forma envolveria atualizar a bruta com uma negação e a partir daí chamar a função agrupar. Mas isso tem um custo
  #de processamento bem maior, porque teria que estar sempre chamando a função agrupar - que é uma função recursiva.
  def negated
    aux = Sentence.new
    aux.operator = LogicalOperator.new(LogicalOperator::VALUES[:negation])
    aux.level = self.level
    aux.right_sentence = Sentence.new(self)
    aux.right_sentence.father = aux
    aux.raw = "(#{LogicalOperator::VALUES[:negation]}#{self.raw})"
    aux.left_sentence.update_level if aux.left_sentence
    aux.right_sentence.update_level if aux.right_sentence
    aux.classify_sentence
    aux
  end

  def copy(sentence)
    if sentence.is_literal?||sentence.is_constant?
      @raw = String.new(sentence.raw)
    end
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentence.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentence.new(sentence.left_sentence,self)
    #@left_sentence.father = self if @left_sentence
    #@right_sentence.father = self if @right_sentence
    @operator = sentence.operator.nil? ? nil : LogicalOperator.new(sentence.operator)
  end

  #TODO: VERIFICAR SE É POSSÍVEL UTILIZAR !IS_LITERAL? (DAVA PROBLEMA POIS UM LITERAL NEGADO TB É UM LITERAL E DEVE SER ATUALIZADO)
  def update_raw_and_classified
    unless @left_sentence.nil? && @right_sentence.nil?
      @raw = "("+(@left_sentence.nil? ? "":@left_sentence.raw) + (@operator.nil? ? "":@operator.value) + (@right_sentence.nil? ? "":@right_sentence.raw)+")"
    end
    classify_sentence
  end

  def update_level
    #if is_literal?
    if @left_sentence.nil? && @right_sentence.nil?
      @level = @father.level
    else
      @level = @father.level + 1
      @left_sentence.update_level unless @left_sentence.nil?
      @right_sentence.update_level unless @right_sentence.nil?
    end
  end

  def update_classified
    classify_sentence
    @left_sentence.update_classified unless @left_sentence.nil?
    @right_sentence.update_classified unless @right_sentence.nil?
  end

  #negação é um literal com filho da direita, por isso ao atualizar sua bruta, devemos olhar seu filho da direita
  def update(raw=nil)
    unless raw
      update_raw_and_classified
      @left_sentence.update_level unless @left_sentence.nil?
      @right_sentence.update_level unless @right_sentence.nil?
      @left_sentence.update_classified unless @left_sentence.nil?
      @right_sentence.update_classified unless @right_sentence.nil?
    else
      @raw = raw if raw
      classify_sentence
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
        old_left = ( @left_sentence ? Sentence.new(@left_sentence) : nil )
        old_right = ( @right_sentence ? Sentence.new(@right_sentence) : nil )
        case @operator.type
          when :conjunction
            if is_formula_and_formula?
              copy @left_sentence
              update
            elsif is_formula_and_not_formula?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              @raw = Constant::VALUES[:bottom]
              classify_sentence
            elsif is_formula_and_up?
              if @left_sentence.is_constant?
                copy @right_sentence
              else
                copy @left_sentence
              end
              update
            elsif is_formula_and_bottom?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALUES[:bottom])
            end
          when :disjunction
            if is_formula_or_formula?
              copy @left_sentence
              update
            elsif is_formula_or_not_formula?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALUES[:up])
            elsif is_formula_or_up?
              @left_sentence, @right_sentence, @operator = nil,nil,nil
              update(Constant::VALUES[:up])
            elsif is_formula_or_bottom?
              if @left_sentence.is_constant?
                copy @right_sentence
              else
                copy @left_sentence
              end
              update
            end
          when :negation
            if is_double_negation?
              copy @right_sentence.right_sentence
              update
            elsif is_not_bottom?
              update(Constant::VALUES[:up])
            elsif is_not_up?
              update(Constant::VALUES[:bottom])
            end
        end

        @left_sentence.simplification unless @left_sentence.nil?
        @right_sentence.simplification unless @right_sentence.nil?

        unless Sentence.equals?(old_left, @left_sentence) && Sentence.equals?(old_right, @right_sentence)
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
      if Sentence.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # φ&φ
  def is_formula_and_formula?
    if @operator.is_conjunction?
      if Sentence.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # φ | (~φ)
  def is_formula_or_not_formula?
    if @operator.is_disjunction?
      if @right_sentence.operator && @right_sentence.operator.is_negation?
        if Sentence.equals?(@left_sentence,@right_sentence.right_sentence)
          return true
        end
      elsif @left_sentence.operator && @left_sentence.operator.is_negation?
        if Sentence.equals?(@left_sentence.right_sentence,@right_sentence)
          return true
        end
      end
    end
    false
  end

  # φ & (~φ)
  def is_formula_and_not_formula?
    if @operator.is_conjunction?
      if @right_sentence.operator && @right_sentence.operator.is_negation?
        if Sentence.equals?(@left_sentence,@right_sentence.right_sentence)
          return true
        end
      elsif @left_sentence.operator && @left_sentence.operator.is_negation?
        if Sentence.equals?(@left_sentence.right_sentence,@right_sentence)
          return true
        end
      end
    end
    false
  end

  # φ & ⊤
  def is_formula_and_up?
    if @operator.is_conjunction?
      if @left_sentence && @right_sentence.is_constant?
        return @right_sentence.classified.first.is_up?
      elsif @left_sentence.is_constant? && @right_sentence
        return @left_sentence.classified.first.is_up?
      end
    end
    false
  end

  # φ & ⊥
  def is_formula_and_bottom?
    if @operator.is_conjunction?
      if @left_sentence && @right_sentence.is_constant?
        return @right_sentence.classified.first.is_bottom?
      elsif @left_sentence.is_constant? && @right_sentence
        return @left_sentence.classified.first.is_bottom?
      end
    end
    false
  end

  # φ & ⊤
  def is_formula_or_up?
    if @operator.is_disjunction?
      if @left_sentence && @right_sentence.is_constant?
        return @right_sentence.classified.first.is_up?
      elsif @left_sentence.is_constant? && @right_sentence
        return @left_sentence.classified.first.is_up?
      end
    end
    false
  end

  # φ & ⊥
  def is_formula_or_bottom?
    if @operator.is_disjunction?
      if @left_sentence && @right_sentence.is_constant?
        return @right_sentence.classified.first.is_bottom?
      elsif @left_sentence.is_constant? && @right_sentence
        return @left_sentence.classified.first.is_bottom?
      end
    end
    false
  end

  # (~(~a))
  def is_double_negation?
    if @operator.is_negation?
      if @right_sentence.operator && @right_sentence.operator.is_negation?
        return true
      end
    end
    false
  end

  def is_bottom?
    return (is_constant? && @classified.first.is_bottom?)
  end

  def is_up?
    return (is_constant? && @classified.first.is_up?)
  end

  def is_not_bottom?
    if (@operator && @operator.is_negation?)
      @right_sentence.is_not_bottom?
    else
      return (is_bottom? && @father && @father.operator && @father.operator.is_negation?)
    end
  end

  def is_not_up?
    if (@operator && @operator.is_negation?)
      @right_sentence.is_not_up?
    else
      return (is_up? && @father && @father.operator && @father.operator.is_negation?)
    end
  end


  #----------------TRANSFORMATION FUNCTION INTO APNF------------------

  def transformation_into_apnf
    self.simplification
    unless @operator.nil?
      old_left = ( @left_sentence ? Sentence.new(@left_sentence) : nil )
      old_right = ( @right_sentence ? Sentence.new(@right_sentence) : nil )

      if @operator.is_negation?
        unless @right_sentence.operator.nil?
          case @right_sentence.operator.type
            when :implication
              copy @right_sentence
              @operator = LogicalOperator.new(LogicalOperator::VALUES[:conjunction])
              @right_sentence = @right_sentence.negated
              @right_sentence.father = self
              update
            when :conjunction
              copy @right_sentence
              @operator = LogicalOperator.new(LogicalOperator::VALUES[:disjunction])
              @left_sentence = @left_sentence.negated
              @right_sentence = @right_sentence.negated
              @right_sentence.father,@left_sentence.father  = self,self
              update
            when :disjunction
              copy @right_sentence
              @operator = LogicalOperator.new(LogicalOperator::VALUES[:conjunction])
              @left_sentence = @left_sentence.negated
              @right_sentence = @right_sentence.negated
              @right_sentence.father,@left_sentence.father  = self,self
              update
          end
          @left_sentence.transformation_into_apnf if @left_sentence
          @right_sentence.transformation_into_apnf if @right_sentence
        end
      else
        case @operator.type
          when :implication
            @operator = LogicalOperator.new(LogicalOperator::VALUES[:disjunction])
            @left_sentence = @left_sentence.negated
            @left_sentence.father = self
            update
        end
        @left_sentence.transformation_into_apnf if @left_sentence
        @right_sentence.transformation_into_apnf if @right_sentence
      end

      unless Sentence.equals?(old_left, @left_sentence) && Sentence.equals?(old_right, @right_sentence)
        update
      end
    end
    self.simplification
  end

  #--------------------------------------------------------------------
  #---------------------TRANSFORMATION INTO DSNF-----------------------
  def transformation_into_dsnf
    negated_sentence_in_apnf = self.negated.transformation_into_apnf
    puts "###### APNF ######"
    puts "#{negated_sentence_in_apnf.raw}"
    initial = [Sentence.new(generate_new_symbol)]
    first_element = Sentence.generate_implication_between(Sentence.new(initial.first), Sentence.new(negated_sentence_in_apnf))
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
    if sentence1.is_literal? && sentence2.is_literal?
      if sentence1.operator && sentence1.operator.is_negation? && (not sentence2.operator)
        if sentence1.right_sentence.raw.eql? sentence2.raw
          return true
        end
      elsif sentence2.operator && sentence2.operator.is_negation? && (not sentence1.operator)
        if sentence2.right_sentence.raw.eql? sentence1.raw
          return true
        end
      end
    end
    false
  end

  def self.same_literals?(sentence1, sentence2)
    return sentence1.raw.eql? sentence2.raw
  end
  #----------------------------------------------------PROTECTED--------------------------------------------------------

  protected

  def first_step_dsnf(universe)
    is_done = false
    while not is_done
      is_done = true
      universe.each_with_index do |el, index|
        if el.right_sentence.operator
          case el.right_sentence.operator.type
            #REGRA 1
            when :conjunction
              left_symbol = Sentence.new(el.left_sentence)              #pega o t
              formula1 = el.right_sentence.left_sentence                #pega o φ1
              formula2 = el.right_sentence.right_sentence               #pega o φ2
              universe.push Sentence.generate_implication_between(left_symbol, formula1)
              left_symbol = Sentence.new(el.left_sentence)              #cria outro t em outra posição da memória
              universe.push Sentence.generate_implication_between(left_symbol, formula2)
              universe.delete_at(index)                                 #tira a sentença do conjunto
              is_done = false

            #REGRA 2
            when :disjunction
              formula = el.right_sentence
              unless formula.right_sentence.is_literal?
                left_symbol = Sentence.new(el.left_sentence)            #pega o t
                new_symbol = Sentence.new(generate_new_symbol)                        #gera novo simbolo t1
                formula1 = el.right_sentence.left_sentence              #pega o φ1
                formula2 = el.right_sentence.right_sentence             #pega o φ2
                aux = Sentence.generate_disjunction_between(formula1, new_symbol) #gera a disjuncao entre φ1 e o novo simbolo
                universe.push Sentence.generate_implication_between(left_symbol, aux)
                universe.push Sentence.generate_implication_between(new_symbol, formula2)
                universe.delete_at(index)
                is_done = false
              else
                unless formula.left_sentence.is_literal?
                  left_symbol = Sentence.new(el.left_sentence)            #pega o t
                  new_symbol = Sentence.new(generate_new_symbol)                        #gera novo simbolo t1
                  formula1 = el.right_sentence.right_sentence             #pega o φ2 (neste caso ele é um literal)
                  formula2 = el.right_sentence.left_sentence              #pega o φ1
                  aux = Sentence.generate_disjunction_between(formula1, new_symbol) #gera a disjuncao entre φ1 e o novo simbolo
                  universe.push Sentence.generate_implication_between(left_symbol, aux)
                  universe.push Sentence.generate_implication_between(new_symbol, formula2)
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
          left_symbol = Sentence.new(el.left_sentence).negated                  #pega o ~t
          disjunction_of_literals_or_literal = el.right_sentence                #pega a disjuncao de literais ou o literal
          universe.push Sentence.generate_disjunction_between(left_symbol, disjunction_of_literals_or_literal)
          universe.delete_at(index)
          is_done = false
        end
      end
    end
  end

  def generate_new_symbol
    new_symbol = Proposition::START_OF_NEW_SYMBOL + Proposition::NEW_SYMBOL_DEFAULT + @@new_symbol_count.to_s
    @@new_symbol_count = @@new_symbol_count.next
    new_symbol
  end

  def classify_sentence
    classified_sentence = []
    buffer = ""
    parenthesis_level = @level
    parenthesis_control = 0

    @raw.chars.each_with_index do |char, index|
      case
        when ( Parenthesis::VALUES.has_value? char )
          parentese = Parenthesis.new(char)
          if parentese.is_open_parenthesis?
            parenthesis_control += 1
            parenthesis_level += 1 unless index==0
            parentese.level = parenthesis_level
            classified_sentence.push parentese
          else
            parentese.level = parenthesis_level
            classified_sentence.push parentese
            parenthesis_level -= 1
            parenthesis_control -= 1
          end

        when ( LogicalOperator::REGEX_UNARY.match char )
          classified_sentence.push LogicalOperator.new(char)

        when ( LogicalOperator::REGEX.match char )
          look_ahead(LogicalOperator, index, char, buffer, classified_sentence, parenthesis_level)

        when ( Proposition::START_OF_NEW_SYMBOL.eql? char )
          buffer.concat char

        when ( Proposition::REGEX.match "#{buffer}#{char}" )
          look_ahead(Proposition, index, char, buffer, classified_sentence, parenthesis_level)

        when ( Constant::REGEX.match char )
          classified_sentence.push Constant.new(char)
      end
    end

    @classified = classified_sentence

    raise ArgumentError, "Number of parethesis is not right." unless (parenthesis_control == 0)
  end

  def look_ahead(kclass, index, char, buffer, classified_sentence, nivel_parentese)
    if @raw[index + 1] && kclass::REGEX.match( "#{buffer}#{char}#{@raw[index + 1]}" )
      buffer.concat char
    else
      classified_sentence.push kclass.new(buffer+char)
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

  def group
    index = 1
    if is_primitive_sentence?
      @left_sentence = Sentence.new(@classified[index].value,@level)
      @operator = @classified[index + 1]
      @right_sentence = Sentence.new(@classified[index + 2].value,@level)
      @left_sentence.father, @right_sentence.father = self, self

    elsif is_negated_sentence?
      @operator = @classified[index]
      #Exemplo: (~a) ou (~1)
      if @classified[index+1].instance_of?(Proposition) or @classified[index+1].instance_of?(Constant)
        @right_sentence = Sentence.new(@classified[index+1].value,@level)
        @right_sentence.father = self
      else
        #Exemplo: #(~(a & b)) ou (~(~a))
        index_closed_parenthesis = index_closed_parenthesis(@level+1)
        aux = @classified[index+1..index_closed_parenthesis].map{|el|el.value}*""
        @right_sentence = Sentence.new(aux,@level+1).group
        @right_sentence.father = self
      end

    elsif is_left_derivative?
      index_closed_parenthesis = index_closed_parenthesis(@level+1)
      aux = @classified[index..index_closed_parenthesis].map{|el|el.value}*""
      @left_sentence = Sentence.new(aux,@level+1).group
      @operator = @classified[index_closed_parenthesis + 1]
      @right_sentence = Sentence.new(@classified[index_closed_parenthesis + 2].value,@level)
      @left_sentence.father, @right_sentence.father = self, self

    elsif is_right_derivative?
      @left_sentence = Sentence.new(@classified[index].value,@level)
      @operator = @classified[index + 1]
      index_closed_parenthesis = index_closed_parenthesis(@level+1,index)
      aux = @classified[(index+2)..index_closed_parenthesis].map{|el|el.value}*""
      @right_sentence = Sentence.new(aux,@level+1).group
      @left_sentence.father, @right_sentence.father = self, self

    elsif is_both_derivative?
      index_closed_parenthesis = index_closed_parenthesis(@level+1)
      aux = @classified[index..index_closed_parenthesis].map{|el|el.value}*""
      @left_sentence = Sentence.new(aux,@level+1).group
      @operator = @classified[index_closed_parenthesis + 1]
      index = index_closed_parenthesis + 2
      index_closed_parenthesis = index_closed_parenthesis(@level+1,index)
      aux = @classified[index..index_closed_parenthesis].map{|el|el.value}*""
      @right_sentence = Sentence.new(aux,@level+1).group
      @left_sentence.father, @right_sentence.father = self, self
    end
    self
  end

  #Exemplo: (a&b)
  def is_primitive_sentence?
    index = 1
    if @classified[index].instance_of?(Proposition) || @classified[index].instance_of?(Constant)
      if @classified[index + 1].instance_of?(LogicalOperator)
        if @classified[index + 2].instance_of?(Proposition) || @classified[index + 2].instance_of?(Constant)
          return true
        end
      end
    end
    false
  end

  #Exemplo: (a&b)->c
  def is_left_derivative?
    index = 1
    if @classified[index].instance_of? Parenthesis
      level = @classified[index].level
      index = index_closed_parenthesis(level)
      if @classified[index+1].instance_of?(LogicalOperator)
        if @classified[index+2].instance_of?(Proposition) || @classified[index+2].instance_of?(Constant)
          return true
        end
      end
    end
    false
  end

  #Exemplo: a->(b&c)
  def is_right_derivative?
    index = 1
    if @classified[index].instance_of?(Proposition) || @classified[index].instance_of?(Constant)
      if @classified[index+1].instance_of? (LogicalOperator)
        if @classified[index+2].instance_of?(Parenthesis)
          return true
        end
      end
    end
    false
  end

  #Exemplo: ((a&b)->(c&d))
  def is_both_derivative?
    index = 1
    if @classified[index].instance_of?(Parenthesis)
      level = @classified[index].level
      index = index_closed_parenthesis(level)
      if @classified[index+1].instance_of?(LogicalOperator)
        if @classified[index+2].instance_of?(Parenthesis)
          return true
        end
      end
    end
    false
  end

  #Exemplo: (~(a&b)) ou (~a)
  def is_negated_sentence?
    index = 1
    if @classified[index] && LogicalOperator::REGEX_UNARY.match(@classified[index].value)
      return true
    end
    false
  end

  def index_closed_parenthesis(level,index=0)
    if index == 0
      @classified.find_index {|el| (el.is_close_parenthesis? if el.instance_of? Parenthesis) && el.level == level}
    else
      aux = Array.new @classified
      aux.fill(0,0..index).find_index {|el| (el.is_close_parenthesis? if el.instance_of? Parenthesis) && el.level == level}
    end
  end

end