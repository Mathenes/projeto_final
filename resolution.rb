class Resolution
  require './sentence'

  attr_reader :file, :sentence, :valid, :id

  IRES_RULE = 0
  URES_RULE = 1

  RULES_NAMES = {ires: 'IRES', ures: 'URES'}

  @@nivel = 0
  @@arq_count = 0

  def initialize(sentence)
    @sentence = sentence
    @valid = false
    initialize_file
  end

  def execute
    dsnf = @sentence.transformation_into_dsnf
    @id = 0
    @valid = resolution(dsnf[:I],dsnf[:U],@id)
    close_file
    @valid
  end

  def initialize_file
    @@arq_count = @@arq_count + 1
    @file = File.new("file_#{@@arq_count}","w")
  end

  def close_file
    @file.close
  end

  def resolution(initial,universe,id)
    initial_local, universe_local = [],[]
    Resolution.reset_sets(initial_local,initial,universe_local,universe)

    if ures_resolution(initial_local,universe_local,id)
      return true
    else
      @file.puts "###### BACK [OUT]######"
      #puts @@nivel if @@nivel < 35
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      if ires_resolution(initial_local,universe_local,id)
        return true
      end
    end
    return false
  end

  def ures_resolution(initial,universe,id)
    @@nivel = @@nivel + 1
    @file.puts "###### ENTROU URES ######"
    unless universe.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,1
      is_done = false
      id_antes = id
      imprime_conjuntos("URES - CONJUNTOS ANTES",initial,"I",universe_local,"U",id_antes)
      while (not is_done) && (i <= universe_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          imprime("PAR",universe_local[i].raw,"U",universe_local[j].raw,"U",RULES_NAMES[:ures])
          universe_local.push comparison(universe_local[i],universe_local[j])
          universe_local[i],universe_local[j] = nil, nil
          universe_local = universe_local.compact
          @id = @id + 1
          is_done = true if universe_local.empty?
          imprime_conjuntos("NOVA CONFIGURAÇÃO",initial,"I",universe_local,"U",@id) if not is_done

          if not is_done
            if resolution(initial,universe_local,@id)
              is_done = true
              universe_local = []
            else
              @file.puts "###### BACK [IN][URES]######"
              universe_local = []
              universe.each{|el|universe_local.push Sentence.new(el)}
              imprime_conjuntos("VOLTOU PARA A CONFIGURAÇÃO",initial,"I",universe_local,"U",id_antes)
              j = j.next
            end
          end
        end
        i = i.next
        j = i + 1
      end
      @@nivel = @@nivel - 1
      @file.puts "###### VALID! ######" if is_done
      @file.puts "###### SAIU URES ######"
      return is_done
    else
      @file.puts "###### SAIU URES ######"
      return false
    end
  end


  def ires_resolution(initial,universe,id)
    @@nivel = @@nivel + 1
    @file.puts "###### ENTROU IRES ######"
    unless initial.empty?
      initial_local, universe_local = [],[]
      Resolution.reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,0
      is_done = false
      id_antes = id
      imprime_conjuntos("IRES - CONJUNTOS ANTES",initial_local,"I",universe_local,"U",id_antes)
      while (not is_done) && (i <= initial_local.count-1)
        while (not is_done) && (j <= universe_local.count-1)

          imprime("PAR",initial_local[i].raw,"I",universe_local[j].raw,"U",RULES_NAMES[:ires])
          initial_local.push comparison(initial_local[i],universe_local[j])
          initial_local[i],universe_local[j] = nil, nil
          universe_local = universe_local.compact
          initial_local = initial_local.compact
          @id = @id + 1
          is_done = true if (initial_local.empty? && (universe_local.count < universe.count))
          imprime_conjuntos("NOVA CONFIGURAÇÃO",initial_local,"I",universe_local,"U",@id) if not is_done

          if not is_done
            if resolution(initial_local,universe_local,@id)
              is_done = true
              universe_local = []
            else
              @file.puts "###### BACK [IN][IRES]######"
              initial_local, universe_local = [],[]
              Resolution.reset_sets(initial_local,initial,universe_local,universe)
              imprime_conjuntos("VOLTOU PARA A CONFIGURAÇÃO",initial_local,"I",universe_local,"U",id_antes)
              j = j.next
            end
          end
        end
        i = i.next
        j = i.next
      end
      @@nivel = @@nivel - 1
      @file.puts "###### VALID! ######" if is_done
      @file.puts "###### SAIU IRES ######"
      return is_done
    else
      @@nivel = @@nivel - 1
      @file.puts "###### SAIU IRES ######"
      return false
    end
  end


  def comparison(sentence1, sentence2)
    sentence1_aux = sentence1
    sentence2_aux = sentence2
    sentence1.each do |el|
      sentence2.each do |el2|
        if Sentence.opposites_literals?(el,el2)
          if el.delete
            sentence1.update
          else
            sentence1_aux = nil
          end
          if el2.delete
            sentence2.update
          else
            sentence2_aux = nil
          end
        elsif Sentence.same_literals?(el,el2)
          if el2.delete
            sentence2.update
          else
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
  end


  def imprime(msg,element1,tag1,element2,tag2,rule)
    @file.puts "###### #{msg} - RULE: #{rule} ######"
    @file.puts "#{element1}  [#{tag1}]"
    @file.puts "#{element2}  [#{tag2}]"
  end

  def imprime_conjunto(msg,set,tag)
    @file.puts "---------------#{msg}-------ID da Configuracao: #{id}--------"
    set.each_with_index{|el,index|@file.puts "#{index}. #{el.raw}     [#{tag}]"}
    @file.puts "--------------------------------------------------------"
  end

  def imprime_conjuntos(msg,set1,tag1,set2,tag2,id)
    @file.puts "---------------#{msg}-------ID da Configuracao: #{id}--------"
    set1.each_with_index{|el,index|@file.puts "#{index}. #{el.raw}     [#{tag1}]"}
    set2.each_with_index{|el,index|@file.puts "#{index}. #{el.raw}     [#{tag2}]"}
    @file.puts "--------------------------------------------------------"
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