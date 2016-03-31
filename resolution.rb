# This class executes the clausal resolution by the application of inference rules IRES and URES and/or new inference rules
# that can be added to the code at the methods designed for it.

#OBSERVATION:
# EXECUTING THE RESOLUTION FOR A SENTENCE
# To execute the resolution for a sentence, the user must follow these steps
# First, a sentence needs to be instantiated: sentence = Sentence.new("(a->b)")
# Afterwards, a resolution needs to be instantiated with the sentence object
# as a parameter: resolution = Resolution.new(sentence)
# Lastly, the execute method is called.


class Resolution
  require './sentence'
  require 'benchmark'

  attr_reader :file, :valid_log_file, :sentence, :valid, :id, :time, :valid_context

  RULES_NAMES = {ires: 'IRES', ures: 'URES'}

  LOG_FILES_DIRECTORY = "./log_files"
  VALID_FILES_DIRECTORY = "./valid_log_files"

  @@arq_count = 0

  # Method that is called automatically when a new resolution is instantiated.
  def initialize(sentence)
    @sentence = sentence
    @valid = false
    @valid_context = []
    initialize_file
  end

  # Method that initializes the log file variable
  def initialize_file
    @@arq_count = @@arq_count + 1
    @file = File.new("#{LOG_FILES_DIRECTORY}/log_file_#{@@arq_count}.txt","w")
    @file.puts "Sentence: #{@sentence.raw}"
    @file.puts "APNF of the negated sentence: #{@sentence.negated.transformation_into_apnf.raw}"
  end

  # Method that executes the prover
  # Output:
  # true if the sentence is valid
  # false otherwise
  def execute
    dsnf = @sentence.transformation_into_dsnf
    @id, @stack = 0,0
    @time = Benchmark.measure{
      @valid = resolution(dsnf[:I],dsnf[:U],@id)
    }
    if @valid
      @file.puts "###### UNSATISFIABLE! FORMULA IS VALID ######" if @valid
      @valid_file = File.new("#{VALID_FILES_DIRECTORY}/valid_log_file_#{@@arq_count}.txt","w")
      print_valid_resolution
      @valid_file.close
    else
      @file.puts "###### SATISFIABLE! ######"
    end
    @file.puts "TOTAL TIME (IN SECS): #{@time.real}"
    @file.close
    @valid
  end

  # Method that creates and saves the log file only with the valid contexts of the proof
  def print_valid_resolution
    @valid_file.puts "Sentence: #{@sentence.raw}"
    @valid_file.puts "APNF of the negated sentence: #{@sentence.negated.transformation_into_apnf.raw}"
    @valid_context.reverse.each_with_index do |el, index|
      initial = el[:initial]
      initial_local = el[:initial_local]
      universe = el[:universe]
      universe_local = el[:universe_local]
      pair = el[:pair]
      rule = el[:rule]
      unless index == (@valid_context.count - 1)
        id_current = el[:id]
        if @valid_context.reverse[index+1][:id_antes]
          id_next = @valid_context.reverse[index+1][:id_antes]
        else
          id_next = @valid_context.reverse[index+1][:id]
        end
      else
        id_current = el[:id_antes]
        id_next = el[:id]
      end
      print_sets("#{rule} - INITIAL CLAUSES", initial, "I", universe, "U", id_current, @valid_file) if (index == 0)
      print("PAIR", pair[0], "U", pair[1], "U", rule, @valid_file)
      if ((@valid_context.count - 1) == index )
        @valid_file.puts "###### UNSATISFIABLE! FORMULA IS VALID ######"
      else
        print_sets("NEW CONFIGURATION", initial_local, "I", universe_local, "U", id_next, @valid_file)
      end
    end
    @valid_file.puts "TOTAL TIME (IN SECS): #{@time.real}"
  end

  #---------------------------------------------------------------------------------------------------------------------

  #-------------------------------------------------RESOLUTION METHOD---------------------------------------------------

  # Method that performs the proof method and its proof strategy. It's a recursive method that works along with two others
  # "ires_resolution()" and "ures_resolution()" - and maybe with "new_resolution_rule()" - throught mutual recursion.
  # Input:
  # initial: the Initial set of clauses of the formula
  # universe: the Universe set of clauses of the formula
  # Output:
  # true if the sentence is valid
  # false otherwise
  def resolution(initial,universe,id)
    initial_local, universe_local = [],[]
    Resolution.reset_sets(initial_local,initial,universe_local,universe)

    if ures_resolution(initial_local,universe_local,id)
      return true
    else
      @file.puts "###### OUTER BACKTRACKING | TRYING IRES RULE ######"
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      if ires_resolution(initial_local,universe_local,id)
        return true
      else
        #REINICIA OS CONJUNTOS LOCAIS PARA VOLTAREM À CONFIGURAÇÃO QUE ESTAVAM ANTES DE ENTRAREM NA RECURSÃO
        Resolution.reset_sets(initial_local,initial,universe_local,universe)

        #TRY A NEW RESOLUTION RULE TO VALIDATE THE FORMULA
        if new_resolution_rule()
          return true
        end
      end
    end
    return false
  end

  #---------------------------------------------------------------------------------------------------------------------

  #----------------------------------------------INFERENCE RULES METHODS------------------------------------------------

  # Method that performs the application of URES inference rule
  # Input:
  # initial: the Initial set of clauses of the formula
  # universe: the Universe set of clauses of the formula
  # id: the id of the current context of clauses
  # Output:
  # true if the sentence is valid
  # false otherwise
  def ures_resolution(initial,universe,id)
    unless universe.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,1
      is_done = false
      has_opposites = false
      id_antes = id
      print_sets("URES - CLAUSES BEFORE",initial,"I",universe_local,"U",id_antes,@file)
      while (not is_done) && (i <= universe_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          print("PAIR",universe_local[i].raw,"U",universe_local[j].raw,"U",RULES_NAMES[:ures],@file)
          pair = [universe_local[i].raw,universe_local[j].raw]
          aux = comparison(universe_local[i],universe_local[j])
          if aux == false
            universe_local = []
            universe.each{|el|universe_local.push Sentence.new(el)}
            j = j.next
            (j > universe_local.count-1) ? @file.puts("###### NO OPPOSITES ######") : @file.puts("###### NO OPPOSITES - NEW PAIR WILL BE TESTED ######")
          else
            has_opposites = true
            universe_local.push aux
            universe_local[i],universe_local[j] = nil, nil
            universe_local = universe_local.compact
            @id = @id + 1
            if universe_local.empty?
              is_done = true
              @valid_context.push({rule: RULES_NAMES[:ures], pair: pair, initial: initial, initial_local: initial_local, universe: universe, universe_local: universe_local, id_antes: id_antes, id: @id})
            end
            print_sets("NEW CONFIGURATION",initial,"I",universe_local,"U",@id,@file) if not is_done
          end
          if (not is_done) && has_opposites
            if resolution(initial,universe_local,@id)
              is_done = true
              @valid_context.push({rule: RULES_NAMES[:ures], pair: pair, initial: initial, initial_local: initial_local, universe: universe, universe_local: universe_local, id: id_antes})
              universe_local = []
            else
              @file.puts "###### INNER BACKTRACKING [URES] | TRYING ANOTHER PAIR OF CLAUSES ######"
              universe_local = []
              universe.each{|el|universe_local.push Sentence.new(el)}
              print_sets("BACK TO CONFIGURATION",initial,"I",universe_local,"U",id_antes,@file)
              j = j.next
              has_opposites = false
            end
          end
        end
        i = i.next
        j = i + 1
      end
      return is_done
    else
      return false
    end
  end

  # Method that performs the application of IRES inference rule
  # Input:
  # initial: the Initial set of clauses of the formula
  # universe: the Universe set of clauses of the formula
  # id: the id of the current context of clauses
  # Output:
  # true if the sentence is valid
  # false otherwise
  def ires_resolution(initial,universe,id)
    unless initial.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,0
      is_done = false
      id_antes = id
      has_opposites = false
      print_sets("IRES - CLAUSES BEFORE",initial_local,"I",universe_local,"U",id_antes,@file)
      while (not is_done) && (i <= initial_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          print("PAIR",initial_local[i].raw,"I",universe_local[j].raw,"U",RULES_NAMES[:ires],@file)
          pair = [initial_local[i].raw,universe_local[j].raw]
          aux = comparison(initial_local[i],universe_local[j])
          if aux == false
            Resolution.reset_sets(initial_local,initial,universe_local,universe)
            j = j.next
            (j > universe_local.count-1) ? @file.puts("###### NO OPPOSITES ######") : @file.puts("###### NO OPPOSITES - NEW PAIR WILL BE TESTED ######")
          else
            has_opposites = true
            initial_local.push aux
            initial_local[i],universe_local[j] = nil, nil
            universe_local = universe_local.compact
            initial_local = initial_local.compact
            @id = @id + 1
            if (initial_local.empty? && (universe_local.count < universe.count))
              is_done = true
              @valid_context.push({rule: RULES_NAMES[:ires], pair: pair, initial: initial, initial_local: initial_local, universe: universe, universe_local: universe_local, id_antes: id_antes, id: @id})
            end
            print_sets("NEW CONFIGURATION",initial_local,"I",universe_local,"U",@id,@file) if not is_done
          end
          if (not is_done) && has_opposites
            if ires_resolution(initial_local,universe_local,@id)
              is_done = true
              @valid_context.push({rule: RULES_NAMES[:ires], pair: pair, initial: initial, initial_local: initial_local, universe: universe, universe_local: universe_local, id: id_antes})
              universe_local = []
            else
              @file.puts "###### INNER BACKTRACKING [IRES] | TRYING ANOTHER PAIR OF CLAUSES ######"
              initial_local, universe_local = [],[]
              Resolution.reset_sets(initial_local,initial,universe_local,universe)
              print_sets("BACK TO CONFIGURATION",initial_local,"I",universe_local,"U",id_antes,@file)
              j = j.next
              has_opposites = false
            end
          end
        end
        i = i.next
        j = i.next
      end
      return is_done
    else
      return false
    end
  end

  #A NEW RESOLUTION RULE CAN BE ADDED
  def new_resolution_rule
    #THE NEW RULE CAN FOLLOW THIS FORMAT

    #is_done = false
    #while not is_done

    #is_done = SOME CONDITIONS THAT VALIDATES THE FORMULA IN A CERTAIN CONFIGURATION OF THE CLAUSES

    #if (not is_done)
    #  TEST IF THE NEXT RECURSION VALIDATES THE FORMULA
    #  if new_resolution_rule() == true
    #    is_done = true
    #  else
    #    # RESET THE SETS AND TRY ANOTHER CONFIGURATION OF THE CLAUSES
    #    #Resolution.reset_sets()
    #  end
    #end
    #end

    false
  end

  #---------------------------------------------------------------------------------------------------------------------

  #---------------------------------------------------USEFUL METHODS---------------------------------------------------

  # Boolean method that verifies if two sentences have complementary literals in each other
  # Input:
  # sentence1: an instance of a sentence
  # sentence2: an instance of a sentence
  # Output:
  # true if the sentences have complementary literals
  # false otherwise
  def has_opposite_literals?(sentence1, sentence2)
    has_opposite = false
    sentence1.each do |el|
      sentence2.each do |el2|
        if Sentence.opposites_literals?(el,el2)
          has_opposite = true
          break
        end
        break if has_opposite
      end
    end
    has_opposite
  end

  # Method that derives two clauses by the application of classical resolution
  # Input:
  # sentence1: an instance of a sentence
  # sentence2: an instance of a sentence
  # Output:
  # nil if the derivation eliminates all the elements in the sentence
  # sentence1 if sentence2 has all its elements eliminated by derivation
  # sentence2 if sentence1 has all its elements eliminated by derivation
  # a disjunction between sentence1 and sentence2 if none of the sentences have all of its elements eliminated by derivation
  # false if there are no complementary literals between these two sentences
  def comparison(sentence1, sentence2)
    has_opposite = false
    sentence1_aux = sentence1
    sentence2_aux = sentence2
    if has_opposite_literals?(sentence1, sentence2)
      sentence1.each do |el|
        sentence2.each do |el2|
          if Sentence.opposites_literals?(el,el2)
            unless el.delete
              sentence1_aux = nil
            end
            unless el2.delete
              sentence2_aux = nil
            end
          elsif Sentence.same_literals?(el,el2)
            unless el2.delete
              sentence2_aux = nil
            end
          end
        end
      end
      if sentence1_aux.nil? && sentence2_aux.nil?
        return nil
      elsif sentence1_aux.nil?
        return sentence2
      elsif sentence2_aux.nil?
        return sentence1
      else
        return Sentence.generate_disjunction_between(sentence1, sentence2)
      end
    else
      false
    end
  end

  # Methods that resets local contexts of INITIAL and UNIVERSE sets
  # Methods that resets local contexts of INITIAL and UNIVERSE sets
  # Input:
  # initial_local: the local context of the Initial set of clauses of the formula
  # initial_global: the global context of the Initial set of clauses of the formula
  # universe_local: the local context of the Universe set of clauses of the formula
  # universe_global: the global context of the Universe set of clauses of the formula
  def self.reset_sets(initial_local, initial_global, universe_local, universe_global)
    initial_local.clear
    unless initial_global.empty?
      initial_local.push Sentence.new(initial_global.first)
    end
    universe_local.clear
    universe_global.each{|el|universe_local.push Sentence.new(el)}
  end

  #---------------------------------------------------------------------------------------------------------------------

  #--------------------------------------------METHODS FOR PRINTING SETS------------------------------------------------

  def print(msg,element1,tag1,element2,tag2,rule,file)
    file.puts "###### #{msg} | USING RULE: #{rule} ######"
    file.puts ""
    file.puts "#{element1}  [#{tag1}]"
    file.puts "#{element2}  [#{tag2}]"
    file.puts "--------------------------------------------------------"
  end

  def print_sets(msg,set1,tag1,set2,tag2,id,file)
    file.puts "---------------#{msg}-------CONFIGURATION ID: #{id}--------"
    set1.each_with_index{|el,index|file.puts "#{index}. #{el.raw}     [#{tag1}]"}
    set2.each_with_index{|el,index|file.puts "#{index}. #{el.raw}     [#{tag2}]"}
    file.puts "--------------------------------------------------------"
  end

  #---------------------------------------------------------------------------------------------------------------------

end