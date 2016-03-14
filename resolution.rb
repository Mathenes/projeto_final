class Resolution
  require './sentence'
  require 'benchmark'

  attr_reader :file, :valid_log_file, :sentence, :valid, :id, :time, :valid_context

  IRES_RULE = 0
  URES_RULE = 1

  RULES_NAMES = {ires: 'IRES', ures: 'URES'}

  LOG_FILES_DIRECTORY = "./log_files"
  VALID_FILES_DIRECTORY = "./valid_log_files"

  @@arq_count = 0

  def initialize(sentence)
    @sentence = sentence
    @valid = false
    @valid_context = []
    initialize_file
  end

  def initialize_file
    @@arq_count = @@arq_count + 1
    @file = File.new("#{LOG_FILES_DIRECTORY}/log_file_#{@@arq_count}.txt","w")
    @file.puts "Sentence: #{@sentence.raw}"
    @file.puts "APNF of the negated sentence: #{@sentence.negated.transformation_into_apnf.raw}"
  end

  def execute
    dsnf = @sentence.transformation_into_dsnf
    @id, @stack = 0,0
    @time = Benchmark.measure{
      @valid = resolution(dsnf[:I],dsnf[:U],@id)
    }
    if @valid
      @file.puts "###### UNSATISFIABLE! ######" if @valid
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
      imprime_conjuntos("#{rule} - INITIAL CLAUSES", initial, "I", universe, "U", id_current, @valid_file) if (index == 0)
      imprime("PAIR", pair[0], "U", pair[1], "U", rule, @valid_file)
      if ((@valid_context.count - 1) == index )
        @valid_file.puts "#{Constant::VALUES[:bottom]}"
      else
        imprime_conjuntos("NEW CONFIGURATION", initial_local, "I", universe_local, "U", id_next, @valid_file)
      end
    end
    @valid_file.puts "TOTAL TIME (IN SECS): #{@time.real}"
  end


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

  def ures_resolution(initial,universe,id)
    #@file.puts "###### ENTROU URES ######"
    unless universe.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,1
      is_done = false
      has_opposites = false
      id_antes = id
      imprime_conjuntos("URES - CLAUSES BEFORE",initial,"I",universe_local,"U",id_antes,@file)
      while (not is_done) && (i <= universe_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          imprime("PAIR",universe_local[i].raw,"U",universe_local[j].raw,"U",RULES_NAMES[:ures],@file)
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
            imprime_conjuntos("NEW CONFIGURATION",initial,"I",universe_local,"U",@id,@file) if not is_done
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
              imprime_conjuntos("BACK TO CONFIGURATION",initial,"I",universe_local,"U",id_antes,@file)
              j = j.next
              has_opposites = false
            end
          end
        end
        i = i.next
        j = i + 1
      end
      #@file.puts "###### SAIU URES ######" unless is_done
      return is_done
    else
      #@file.puts "###### SAIU URES ######" unless is_done
      return false
    end
  end


  def ires_resolution(initial,universe,id)
    #@file.puts "###### ENTROU IRES ######"
    unless initial.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,0
      is_done = false
      id_antes = id
      has_opposites = false
      imprime_conjuntos("IRES - CLAUSES BEFORE",initial_local,"I",universe_local,"U",id_antes,@file)
      while (not is_done) && (i <= initial_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          imprime("PAIR",initial_local[i].raw,"I",universe_local[j].raw,"U",RULES_NAMES[:ires],@file)
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
            imprime_conjuntos("NEW CONFIGURATION",initial_local,"I",universe_local,"U",@id,@file) if not is_done
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
              imprime_conjuntos("BACK TO CONFIGURATION",initial_local,"I",universe_local,"U",id_antes,@file)
              j = j.next
              has_opposites = false
            end
          end
        end
        i = i.next
        j = i.next
      end
      #@file.puts "###### SAIU IRES ######" unless is_done
      return is_done
    else
      #@file.puts "###### SAIU IRES ######" unless is_done
      return false
    end
  end

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


  def imprime(msg,element1,tag1,element2,tag2,rule,file)
    file.puts "###### #{msg} | USING RULE: #{rule} ######"
    file.puts ""
    file.puts "#{element1}  [#{tag1}]"
    file.puts "#{element2}  [#{tag2}]"
    file.puts "--------------------------------------------------------"
  end

  def imprime_conjuntos(msg,set1,tag1,set2,tag2,id,file)
    file.puts "---------------#{msg}-------CONFIGURATION ID: #{id}--------"
    set1.each_with_index{|el,index|file.puts "#{index}. #{el.raw}     [#{tag1}]"}
    set2.each_with_index{|el,index|file.puts "#{index}. #{el.raw}     [#{tag2}]"}
    file.puts "--------------------------------------------------------"
  end

  def self.reset_sets(initial_local, initial_global, universe_local, universe_global)
    initial_local.clear
    unless initial_global.empty?
      initial_local.push Sentence.new(initial_global.first)
    end
    universe_local.clear
    universe_global.each{|el|universe_local.push Sentence.new(el)}
  end

end