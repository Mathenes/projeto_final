# This class operates over a sentence (formula).
# A sentence has the following structure:
# (See LogicalOperator, Proposition and Constant classes to find out what values can be inputed as an operator, a
# proposition and a constant, respectively)

# It has the following instance variables:
# @father         -> a Sentence-type variable that holds the reference of a sentence that is the father of this one
# @raw            -> a String-type variable that holds the value of this sentence in its string form inputed by the user
# @classified     -> an Array-type variable that holds the value of an array where each element represents each element
#                    of this sentence classified by its own type, e.g, a proposition, or a logical operator and so on
# @right_sentence -> a Sentence-type variable that holds the reference of a sentence that is the right son, i.e, the right
#                    subsentence of this one.
# @left_sentence  -> a Sentence-type variable that holds the reference of a sentence that is the left son, i.e, the left
#                    subsentence of this one.
# @operator       -> a LogicalOperator-type variable that holds the value of the main operator of this sentence
# @level          -> a Integer-type variable that holds the value of this sentence's level

# For example, consider the sentence ( (~x) & ((0|1) & (y->z)) );
# This sentence will be represented as a binary tree. Its syntax tree is as follows:

#             &
#          /     \
#         /       \
#        /         \
#       ~           &
#        \        /   \
#         \     /       \
#          x   |        ->
#            /   \     /  \
#           /     \   /    \
#          0       1 x      z

# Where,
# - @father is nil
# - @raw is "((~x)&((0|1)&(y->z)))"
# - @classified is representend by an array [Parenthesis (, Parenthesis (, Proposition ~x, LogicalOperator &, Parenthesis ( ...and so on ]
# - @right_sentence is the subsentence represented by ((0|1)&(y->z))). Recursively, in this right_sentence happens the same for its elements
# - @left_sentence is the subsentence represented by (~x). Recursively, in this right_sentence happens the same for its elements
# - @operator is the logical_operator represented by &
# - @level is 1

#OBSERVATION:
# INPUTING A SENTENCE
# To input a sentence in the program the user needs to call the .new method in Sentence to start the initialize method in this class.
# For example, to input a sentence the user should do:  sentence = Sentence.new("(a->b)")
# where "(a->b)" is a valid sentence in this program.

#VALID SENTENCES
# The user has to follow some rules to input valid sentences in this program.
# No parenthesis should be forgotten, even outer parenthesis - as well as parenthesis in double negation (~(~(a&b)).
# Propositions musb be inserted following the regular expression [a-zA-Z].

#EXAMPLES OF VALID SENTENCES
# 1. (∼(∼(a -> b)))
# 2. (p | (q | (r|s)))
# 3. (aadB & chfg)
# 4. ( (((a&b)|(c&d)) -> ((f&g)|(g&h))) -> (x&y) )


class Sentence
  require './proposition.rb'
  require './logical_operator.rb'
  require './parenthesis.rb'
  require './constant.rb'
  #require 'pry'

  #Class variable that holds the value of the last created new symbol (for resolution)
  @@new_symbol_count = 0

  attr_accessor :father, :raw, :classified, :right_sentence, :left_sentence, :operator, :level


  # Method that is called automatically when a new sentence is created. A new sentence can be created by its string
  # form or by passing an instance of a sentence as a parameter. Or an empty sentence can be create if no parameters are inputed.
  # Input:
  # sentence: A sentence in its string form or an instance of a sentence;
  # father_or_level: When passing a string form of a sentece, you can pass its level too. When passing an instance of a sentence
  #                  you can pass the instance of a sentence that will be its father.
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

  # Method thats is called when the method above receive an instance of a sentence as parameter
  #Input:
  # sentence: An instance of a sentence
  # father : An instance of a sentence that will be the father of the sentence passed in the parameter above
  def initialize_with_instance(sentence,father)
    @father = sentence.father.nil? ? nil : father
    @raw = String.new(sentence.raw)
    @classified = Array.new(sentence.classified)
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentence.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentence.new(sentence.left_sentence,self)
    @operator = sentence.operator.nil? ? nil : LogicalOperator.new(sentence.operator)
    @level = sentence.level
  end

  # Method that deletes a literal of a sentence by erasing its reference. Must navigate to a literal and call this method.
  # Output:
  # true if succeeded
  # false otherwise
  def delete
    if self.father
      if self.is_left_son?
        self.father.copy(self.father.right_sentence)
      elsif self.is_right_son?
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

  # Method that negates a sentence.
  # Output:
  # a new instance of the sentence in its negated form
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

  # A method that copies another instance of a sentence.
  # Input:
  # sentence: an instance of a sentence
  def copy(sentence)
    if sentence.is_literal?||sentence.is_constant?
      @raw = String.new(sentence.raw)
    end
    @right_sentence = sentence.right_sentence.nil? ? nil : Sentence.new(sentence.right_sentence,self)
    @left_sentence = sentence.left_sentence.nil? ? nil : Sentence.new(sentence.left_sentence,self)
    @operator = sentence.operator.nil? ? nil : LogicalOperator.new(sentence.operator)
  end
  #---------------------------------------------------------------------------------------------------------------------

  #---------------------------------------------------BOOLEAN METHODS---------------------------------------------------

  # Boolean method that tests if the sentence is a literal
  def is_literal?
    if @operator && @operator.is_negation?
      @right_sentence.is_literal?
    else
      @left_sentence.nil? && @right_sentence.nil?
    end
  end

  # Boolean method that tests if the sentence is a constant
  def is_constant?
    @classified.first.instance_of? Constant
  end

  # Boolean method that tests if the sentence is the left subsentence of its father
  def is_left_son?
    if @father
      return Sentence.equals?(@father.left_sentence, self)
    else
      return false
    end
  end

  # Boolean method that tests if the sentence is the right subsentence of its father
  def is_right_son?
    if @father
      return Sentence.equals?(@father.right_sentence, self)
    else
      return false
    end
  end

  # Boolean method that tests if the sentence is of the form: (φ | φ)
  def is_formula_or_formula?
    if @operator.is_disjunction?
      if Sentence.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # Boolean method that tests if the sentence is of the form: (φ & φ)
  def is_formula_and_formula?
    if @operator.is_conjunction?
      if Sentence.equals?(@left_sentence, @right_sentence)
        return true
      end
    end
    false
  end

  # Boolean method that tests if the sentence is of the form: (φ | (~φ))
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

  # Boolean method that tests if the sentence is of the form: (φ & (~φ))
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

  # Boolean method that tests if the sentence is of the form: (φ & ⊤)
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

  # Boolean method that tests if the sentence is of the form: (φ & ⊥)
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

  # Boolean method that tests if the sentence is of the form: (φ & ⊤)
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

  # Boolean method that tests if the sentence is of the form: (φ & ⊥)
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

  # Boolean method that tests if the sentence is of the form: (~(~a))
  def is_double_negation?
    if @operator.is_negation?
      if @right_sentence.operator && @right_sentence.operator.is_negation?
        return true
      end
    end
    false
  end

  # Boolean method that tests if the sentence is the constant bottom
  def is_bottom?
    return (is_constant? && @classified.first.is_bottom?)
  end

  # Boolean method that tests if the sentence is the constant up
  def is_up?
    return (is_constant? && @classified.first.is_up?)
  end

  # Boolean method that tests if the sentence is not the constant bottom
  def is_not_bottom?
    if (@operator && @operator.is_negation?)
      @right_sentence.is_not_bottom?
    else
      return (is_bottom? && @father && @father.operator && @father.operator.is_negation?)
    end
  end

  # Boolean method that tests if the sentence is not the constant up
  def is_not_up?
    if (@operator && @operator.is_negation?)
      @right_sentence.is_not_up?
    else
      return (is_up? && @father && @father.operator && @father.operator.is_negation?)
    end
  end
  #---------------------------------------------------------------------------------------------------------------------

  #----------------------------------------------------USEFUL METHODS---------------------------------------------------

  # Method that iterates over all subsentences of this sentence.
  # Input:
  # &block: a block that work over the subsentences elements
  # Output:
  # each subsentence of this sentence until reaching the leafs, i.e, the literals
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

  # The to_string method of this class
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

  # Method that finds all the propositional symbols of this sentence
  # Output:
  # an array of propositional symbols of this sentence
  def propositional_symbols
    symbols = []
    @classified.each do |el|
      symbols.push el if el.instance_of? Proposition
    end
    symbols
  end
  #---------------------------------------------------------------------------------------------------------------------

  #------------------------------------------------------SELF METHODS---------------------------------------------------
  #http://codereview.stackexchange.com/questions/6774/check-if-a-binary-tree-is-a-subtree-of-another-tree
  # Method that tests if two sentences are exactly the same
  # Input:
  # sentence1: an instance of a sentence
  # sentence2: an instance of a sentence
  # Output:
  # true if the sentences are equals
  # false otherwise
  def self.equals?(sentence1, sentence2)
    return true if (sentence1 == sentence2)
    return false if (sentence1 == nil || sentence2 == nil)
    return false if (sentence1.raw != sentence2.raw)
    return Sentence.equals?(sentence1.left_sentence, sentence2.left_sentence) && Sentence.equals?(sentence1.right_sentence, sentence2.right_sentence)
  end

  # Method that tests if two literals are opposites
  # Input:
  # literal1: an instance of a sentence that is a literal
  # literal2: an instance of a sentence that is a literal
  # Output:
  # true if the literals are opposites
  # false otherwise
  def self.opposites_literals?(literal1, literal2)
    if literal1.is_literal? && literal2.is_literal?
      if literal1.operator && literal1.operator.is_negation? && (not literal2.operator)
        if literal1.right_sentence.raw.eql? literal2.raw
          return true
        end
      elsif literal2.operator && literal2.operator.is_negation? && (not literal1.operator)
        if literal2.right_sentence.raw.eql? literal1.raw
          return true
        end
      end
    end
    false
  end

  # Method that tests if two literals are the same by their raw values
  # Input:
  # literal1: an instance of a sentence that is a literal
  # literal2: an instance of a sentence that is a literal
  # Output:
  # true if the literals are same
  # false otherwise
  def self.same_literals?(literal1, literal2)
    return literal1.raw.eql? literal2.raw
  end

  # Method that generates a new sentence that is the implication of two sentences.
  # sentence1: an instance of a sentence
  # sentence2: an instance of a sentence
  # Output:
  # an instance of a sentence that is the implication of the two sentences passed as parameters
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

  # Method that generates a new sentence that is the disjunction of two sentences.
  # sentence1: an instance of a sentence
  # sentence2: an instance of a sentence
  # Output:
  # an instance of a sentence that is the disjunction of the two sentences passed as parameters
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
  #---------------------------------------------------------------------------------------------------------------------

  #---------------------------------------------SENTENCE UPDATE METHODS-------------------------------------------------
  #negação é um literal com filho da direita, por isso ao atualizar sua bruta, devemos olhar seu filho da direita
  # Method that updates the sentence and its subsentences when it gets modified by simplification or wherever.
  # Input:
  # raw: an optional string form of a sentence when needed to manually modify its raw value
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

  #TODO: VERIFICAR SE É POSSÍVEL UTILIZAR !IS_LITERAL? (DAVA PROBLEMA POIS UM LITERAL NEGADO TB É UM LITERAL E DEVE SER ATUALIZADO)
  # An assistive method for the update method above that updates raw and classified through its right and left subsentences
  def update_raw_and_classified
    unless @left_sentence.nil? && @right_sentence.nil?
      @raw = "("+(@left_sentence.nil? ? "":@left_sentence.raw) + (@operator.nil? ? "":@operator.value) + (@right_sentence.nil? ? "":@right_sentence.raw)+")"
    end
    classify_sentence
  end

  # An assistive method for the update method above that updates the level of its right and left subsentences by using the level
  # of the father
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

  # An assistive method for the update method above that updates classified variable of its right and left subsentences
  def update_classified
    classify_sentence
    @left_sentence.update_classified unless @left_sentence.nil?
    @right_sentence.update_classified unless @right_sentence.nil?
  end
  #---------------------------------------------------------------------------------------------------------------------

  #-----------------------------------------------SIMPLIFICATION FUNCTION-----------------------------------------------
  # Recursive method that simplifies this sentence by exhaustively applying the simplification rules contained in the
  # paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  # Output:
  # this sentence simplified by the simplification rules
  def simplification
    changed = true
    while changed
      changed = false
      unless @operator.nil?
        old_left = ( @left_sentence ? Sentence.new(@left_sentence) : nil )
        old_right = ( @right_sentence ? Sentence.new(@right_sentence) : nil )
        case @operator.type
          when :conjunction
            simplification_rules_for_conjunction

            #  ******* NEW APNF RULES FOR NEGATED IMPLICATION FORMULA CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
            #  ******* FOR EXAMPLE:
            new_simplification_rules_for_conjunction()

          when :disjunction
            simplification_rules_for_disjunction

            #  ******* NEW APNF RULES FOR NEGATED IMPLICATION FORMULA CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
            #  ******* FOR EXAMPLE:
            new_simplification_rules_for_disjunction()

          when :negation
            simplification_rules_for_negation

            #  ******* NEW SIMPLIFICATION RULES FOR NEGATION CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
            #  ******* FOR EXAMPLE:
            new_simplification_rules_for_negation()

          when :new_operator
            # ******* OR A NEW OPERATOR NOT USED BEFORE CAN BE ADDED IN THE SIMPLIFICATION - LIKE IMPLICATION FOR EXAMPLE *******

            # ******* AND A NEW SIMPLIFICATION RULE CAN BE ADDED TO THIS OPERATOR *******
            # ******* FOR EXAMPLE: *******
            simplification_rules_for_new_operator()

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
  #---------------------------------------------------------------------------------------------------------------------

  #--------------------------------------------APNF TRANSFORMATION FUNCTION---------------------------------------------
  # Recursive method that transforms this sentence in its Anti-Prenex Normal Form (APNF) by recursively applying the
  # transformation rules contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  # Output:
  # the APNF form of this sentence
  def transformation_into_apnf
    self.simplification
    unless @operator.nil?
      old_left = ( @left_sentence ? Sentence.new(@left_sentence) : nil )
      old_right = ( @right_sentence ? Sentence.new(@right_sentence) : nil )

      if @operator.is_negation?
        unless @right_sentence.operator.nil?
          case @right_sentence.operator.type
            when :implication
              apnf_rules_for_negated_implication

              #  ******* NEW APNF RULES FOR NEGATED IMPLICATION FORMULA CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
              #  ******* FOR EXAMPLE:
              new_apnf_rules_for_negated_implication()

            when :conjunction
              apnf_rules_for_negated_conjunction

              #  ******* NEW APNF RULES FOR NEGATED CONJUNCTION FORMULA CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
              #  ******* FOR EXAMPLE:
              new_apnf_rules_for_negated_conjunction()

            when :disjunction
              apnf_rules_for_negated_disjunction

              #  ******* NEW APNF RULES FOR NEGATED DISJUNCTION FORMULA CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
              #  ******* FOR EXAMPLE:
              new_apnf_rules_for_negated_disjunction()

            when :new_operator
              # ******* OR A NEW OPERATOR NOT USED BEFORE CAN BE ADDED IN THE SIMPLIFICATION - LIKE NEGATION FOR EXAMPLE *******

              # ******* AND A NEW SIMPLIFICATION RULE CAN BE ADDED TO THIS OPERATOR *******
              # ******* FOR EXAMPLE: *******
              apnf_rules_for_negated_new_operator()
          end
          @left_sentence.transformation_into_apnf if @left_sentence
          @right_sentence.transformation_into_apnf if @right_sentence
        end
      else
        case @operator.type
          when :implication
            apnf_rules_for_implication

          #  ******* NEW APNF RULES FOR IMPLICATION CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
          #  ******* FOR EXAMPLE:
          new_apnf_rules_for_implication()

          #  ******* OR NEW RULES FOR CONJUNCTION AND DISJUNCTION CAN BE ADDED TOO, IN A NEW OPTION FOR THE CASE
          #  ******* FOR EXAMPLE:
          when :conjunction
            new_apnf_rules_for_conjunction()

          when :disjunction
            new_apnf_rules_for_disjunction()

          when :new_operator
            # ******* OR A NEW OPERATOR NOT USED BEFORE CAN BE ADDED IN THE SIMPLIFICATION - LIKE NEGATION FOR EXAMPLE *******

            # ******* AND A NEW SIMPLIFICATION RULE CAN BE ADDED TO THIS OPERATOR *******
            # ******* FOR EXAMPLE: *******
            apnf_rules_for_new_operator()

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
  #---------------------------------------------------------------------------------------------------------------------

  #--------------------------------------------DSNF TRANSFORMATION FUNCTION---------------------------------------------
  # A method that transforms this sentence in its Divided Separated Normal Form (DSNF) by recursively applying the
  # transformation rules contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  # Output:
  # the DSNF form of this sentence
  def transformation_into_dsnf
    negated_sentence_in_apnf = self.negated.transformation_into_apnf
    initial = [Sentence.new(generate_new_symbol)]
    first_element = Sentence.generate_implication_between(Sentence.new(initial.first), Sentence.new(negated_sentence_in_apnf))
    universe = [first_element]

    #RULES 1 AND 2 OF THE PAPER
    first_step_dsnf(universe)
    #RULE 6 OF THE PAPER
    second_step_dsnf(universe)

    universe.each do |clause|
      clause.simplification
    end

    return {:I => initial, :U => universe}
  end
  #---------------------------------------------------------------------------------------------------------------------

  #-----------------------------------------------PROTECTED METHODS-----------------------------------------------------

  protected
  #------------------------------------------------ DSNF METHODS -------------------------------------------------------
  # An assistive method for the transformation_into_dsnf method above that executes the 1st and 2nd transformation rules
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def first_step_dsnf(universe)
    is_done = false
    while not is_done
      is_done = true
      universe.each_with_index do |clause, index|
        right_sentence_current_clause = clause.right_sentence
        if right_sentence_current_clause.operator
          case right_sentence_current_clause.operator.type
            when :conjunction
              dsnf_rules_for_conjunction(clause, index, right_sentence_current_clause, universe)
              is_done = false

              #  ******* NEW DSNF RULES FOR CONJUNCTION CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
              #  ******* FOR EXAMPLE:
              new_dsnf_rules_for_conjunction()

            when :disjunction
              unless right_sentence_current_clause.right_sentence.is_literal?
                #IF THE RIGHT SENTENCE IS A LITERAL, WE FOLLOW THE RULE EXACTLY THE WAY IT APPEARS IN THE PAPER TAKING FIRST THE LEFT SENTENCE
                #AND THEN THE RIGHT SENTENCE AS ARGUMENT
                dsnf_rules_for_disjunction(clause, index, right_sentence_current_clause.left_sentence, right_sentence_current_clause.right_sentence, universe)
                is_done = false

                #  ******* NEW DSNF RULES FOR DISJUNTION CAN BE ADDED HERE AS A METHOD JUST LIKE THE METHOD ABOVE *******
                #  ******* FOR EXAMPLE:
                new_dsnf_rules_for_disjunction()

              else
                #HOWEVER, THE RULE IS ASSOCIATIVE AND COMMUTATIVE. SO, IF THE LEFT SENTENCE IS THE LITERAL WE INVERT THE ORDER AND TAKE
                #FIRST THE RIGHT SENTENCE AND THEN THE LEFT SENTENCE AS ARGUMENT
                unless right_sentence_current_clause.left_sentence.is_literal?
                  dsnf_rules_for_disjunction(clause, index, right_sentence_current_clause.right_sentence, right_sentence_current_clause.left_sentence, universe)
                  is_done = false
                end
              end

            when :new_operator
              # ******* OR A NEW OPERATOR NOT USED BEFORE CAN BE ADDED - LIKE NEGATION FOR EXAMPLE *******

              # ******* AND A NEW SIMPLIFICATION RULE CAN BE ADDED TO THIS OPERATOR *******
              # ******* FOR EXAMPLE: *******
              dsnf_rules_for_new_operator()
          end
        end
      end
    end
  end

  # An assistive method for the transformation_into_dsnf method above that executes the 6th transformation rule
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def second_step_dsnf(universe)
    is_done = false
    while not is_done
      is_done = true
      universe.each_with_index do |clause, index|
        if clause.operator.is_implication?
          left_symbol = Sentence.new(clause.left_sentence).negated                  #pega o ~t
          disjunction_of_literals_or_literal = clause.right_sentence                #pega a disjuncao de literais ou o literal
          universe.push Sentence.generate_disjunction_between(left_symbol, disjunction_of_literals_or_literal)
          universe.delete_at(index)
          is_done = false
        end
      end
    end
  end

  # Method that generates new symbol to be used in a clause of the DSNF form
  # Output:
  # a string containing the string form of a propositional symbol
  def generate_new_symbol
    new_symbol = Proposition::START_OF_NEW_SYMBOL + Proposition::NEW_SYMBOL_DEFAULT + @@new_symbol_count.to_s
    @@new_symbol_count = @@new_symbol_count.next
    new_symbol
  end
  #---------------------------------------------------------------------------------------------------------------------

  #------------------------------------------------CLASSIFYING SENTENCES------------------------------------------------
  # Method that creates the array of the @classified instance variable with all the elements of this sentence classified
  # by their own types
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

  # An assistive method that is used in the classify_sentence method above
  def look_ahead(kclass, index, char, buffer, classified_sentence, nivel_parentese)
    if @raw[index + 1] && kclass::REGEX.match( "#{buffer}#{char}#{@raw[index + 1]}" )
      buffer.concat char
    else
      classified_sentence.push kclass.new(buffer+char)
      buffer.clear
    end
  end
  #---------------------------------------------------------------------------------------------------------------------

  #-----------------------------------------------------GROUPING--------------------------------------------------------
  # Method that recursively creates the tree, i.e, by linking each sentence to its subsentences (right and left sentences)
  # recursively.
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
  #---------------------------------------------------------------------------------------------------------------------

  #--------------------------------------------------GROUPING RULES-----------------------------------------------------

  # Boolean method for creating the subsentences that tests if a sentence is of the form: (a&b)
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

  # Boolean method for creating the subsentences that tests if a sentence is of the form: (a&b)->c
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

  # Boolean method for creating the subsentences that tests if a sentence is of the form: a->(b&c)
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

  # Boolean method for creating the subsentences that tests if a sentence is of the form: ((a&b)->(c&d))
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

  # Boolean method for creating the subsentences that tests if a sentence is of the form: (~(a&b)) ou (~a)
  def is_negated_sentence?
    index = 1
    if @classified[index] && LogicalOperator::REGEX_UNARY.match(@classified[index].value)
      return true
    end
    false
  end

  # Assistive method for the group method above
  def index_closed_parenthesis(level,index=0)
    if index == 0
      @classified.find_index {|el| (el.is_close_parenthesis? if el.instance_of? Parenthesis) && el.level == level}
    else
      aux = Array.new @classified
      aux.fill(0,0..index).find_index {|el| (el.is_close_parenthesis? if el.instance_of? Parenthesis) && el.level == level}
    end
  end
  #---------------------------------------------------------------------------------------------------------------------

  #-----------------------------------------------SIMPLIFICATION RULES--------------------------------------------------
  # Method that has the simplification rules for conjunction
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def simplification_rules_for_conjunction
    if is_formula_and_formula?
      copy @left_sentence
      update
    elsif is_formula_and_not_formula?
      @left_sentence, @right_sentence, @operator = nil,nil,nil
      update(Constant::VALUES[:bottom])
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
  end

  # Method that has the simplification rules for disjunction
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def simplification_rules_for_disjunction
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
  end

  # Method that has the simplification rules for negation
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def simplification_rules_for_negation
    if is_double_negation?
      copy @right_sentence.right_sentence
      update
    elsif is_not_bottom?
      update(Constant::VALUES[:up])
    elsif is_not_up?
      update(Constant::VALUES[:bottom])
    end
  end

  # ****** NEW RULES FOR SIMPLIFICATION CAN BE ADDED HERE
  def new_simplification_rules_for_conjunction
  end
  def new_simplification_rules_for_disjunction
  end
  def new_simplification_rules_for_negation
  end
  def simplification_rules_for_new_operator
  end
  #---------------------------------------------------------------------------------------------------------------------

  #----------------------------------------------------APNF RULES-------------------------------------------------------
  # Method that executes the following APNF transformation rule: α(¬(φ → ψ)) = (α(φ) ∧ α(¬ψ))
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def apnf_rules_for_negated_implication
    copy @right_sentence
    @operator = LogicalOperator.new(LogicalOperator::VALUES[:conjunction])
    @right_sentence = @right_sentence.negated
    @right_sentence.father = self
    update
  end

  # Method that executes the following APNF transformation rule: α(¬(φ ∧ ψ)) = (α(¬φ) ∨ α(¬ψ))
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def apnf_rules_for_negated_conjunction
    copy @right_sentence
    @operator = LogicalOperator.new(LogicalOperator::VALUES[:disjunction])
    @left_sentence = @left_sentence.negated
    @right_sentence = @right_sentence.negated
    @right_sentence.father,@left_sentence.father  = self,self
    update
  end

  # Method that executes the following APNF transformation rule: α(¬(φ ∨ ψ)) = (α(¬φ) ∧ α(¬ψ))
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def apnf_rules_for_negated_disjunction
    copy @right_sentence
    @operator = LogicalOperator.new(LogicalOperator::VALUES[:conjunction])
    @left_sentence = @left_sentence.negated
    @right_sentence = @right_sentence.negated
    @right_sentence.father,@left_sentence.father  = self,self
    update
  end

  # Method that executes the following APNF transformation rule: α(φ → ψ) = α(¬φ) ∨ α(ψ)
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def apnf_rules_for_implication
    @operator = LogicalOperator.new(LogicalOperator::VALUES[:disjunction])
    @left_sentence = @left_sentence.negated
    @left_sentence.father = self
    update
  end

  # ****** NEW RULES FOR APNF CAN BE ADDED HERE

  def new_apnf_rules_for_negated_implication
  end
  def new_apnf_rules_for_negated_disjunction
  end
  def new_apnf_rules_for_negated_conjunction
  end
  def new_apnf_rules_for_implication
  end
  def new_apnf_rules_for_disjunction
  end
  def new_apnf_rules_for_conjunction
  end
  def apnf_rules_for_negated_new_operator
  end
  def apnf_rules_for_new_operator
  end
  #---------------------------------------------------------------------------------------------------------------------

  #----------------------------------------------------DSNF RULES-------------------------------------------------------
  # Method that executes the following DSNF transformation rule: {t->(ψ1 ∧ ψ2)} −→ {t -> ψ1,t -> ψ2}
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def dsnf_rules_for_conjunction(clause, index, right_sentence_current_clause, universe)
    t = Sentence.new(clause.left_sentence)                               #pega o t
    formula1 = right_sentence_current_clause.left_sentence               #pega o φ1
    formula2 = right_sentence_current_clause.right_sentence              #pega o φ2
    universe.push Sentence.generate_implication_between(t, formula1)
    t = Sentence.new(clause.left_sentence)                            #cria outro t em outra posição da memória
    universe.push Sentence.generate_implication_between(t, formula2)
    universe.delete_at(index)                                                    #tira a sentença do conjunto
  end

  # Method that executes the following DSNF transformation rule: {t->(ψ1 ∨ ψ2)} −→ {t→(ψ1 ∨ t1),t1 -> ψ2}
  # contained in the paper that can be accessed in http://www.sciencedirect.com/science/article/pii/S1571066115000122
  def dsnf_rules_for_disjunction(clause, index, left_sentence, right_sentence, universe)
    t = Sentence.new(clause.left_sentence)                                #pega o t
    new_symbol = Sentence.new(generate_new_symbol)                        #gera novo simbolo t1
    formula1 = left_sentence                                              #pega o φ1
    formula2 = right_sentence                                             #pega o φ2
    formula_or_new_symbol = Sentence.generate_disjunction_between(formula1, new_symbol)     #gera a disjuncao entre φ1 e o novo simbolo
    universe.push Sentence.generate_implication_between(t, formula_or_new_symbol)
    universe.push Sentence.generate_implication_between(new_symbol, formula2)
    universe.delete_at(index)
  end

  # ****** NEW RULES FOR DSNF CAN BE ADDED HERE

  def new_dsnf_rules_for_conjunction
  end
  def new_dsnf_rules_for_disjunction
  end
  def dsnf_rules_for_new_operator
  end
  #---------------------------------------------------------------------------------------------------------------------
end