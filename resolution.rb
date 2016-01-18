class Resolution
  require './sentenca'

  IRES_RULE = 0
  URES_RULE = 1

  RULES_NAMES = {ires: 'IRES', ures: 'URES'}

  @@nivel = 0

  def self.resolution(initial,universe)
    initial_local, universe_local = [],[]
    reset_sets(initial_local,initial,universe_local,universe)

    if ures_resolution(initial_local,universe_local)
      return true
    else
      puts "###### BACK [OUT]######"
      reset_sets(initial_local,initial,universe_local,universe)

      if ires_resolution(initial_local,universe_local)
        return true
      end
    end
    return false
  end

  def self.ures_resolution(initial,universe)
    puts "###### ENTROU URES ######"
    initial_local, universe_local = [],[]
    reset_sets(initial_local,initial,universe_local,universe)

    i,j = 0,1
    is_done = false
    imprime_conjuntos("URES - CONJUNTOS ANTES",initial,"I",universe_local,"U")
    while not is_done and i <= universe_local.count-1
      while not is_done and j <= universe_local.count-1

        imprime("PAR",universe_local[i].bruta,"U",universe_local[j].bruta,"U",RULES_NAMES[:ures])
        universe_local.push comparison(universe_local[i],universe_local[j])
        universe_local[i],universe_local[j] = nil, nil
        universe_local = universe_local.compact
        imprime_conjuntos("NOVA CONFIGURAÇÃO",initial,"I",universe_local,"U")
        is_done = true if universe_local.empty?

        if not is_done
          if resolution(initial,universe_local)
            is_done = true
            universe_local = []
          else
            puts "###### BACK [IN][URES]######"
            universe_local = []
            universe.each{|el|universe_local.push Sentenca.new(el)}
            imprime_conjuntos("VOLTOU PARA A CONFIGURAÇÃO",initial,"I",universe_local,"U")
            j = j.next
          end
        end
      end
      i = i.next
      j = i + 1
    end
    puts "###### SAIU URES ######"
    return universe_local.empty?
  end


  def self.ires_resolution(initial,universe)
    puts "###### ENTROU IRES ######"
    unless initial.empty?
      initial_local, universe_local = [],[]
      reset_sets(initial_local,initial,universe_local,universe)

      i,j = 0,0
      is_done = false
      imprime_conjuntos("IRES - CONJUNTOS ANTES",initial_local,"I",universe_local,"U")

      while not is_done and i <= initial_local.count-1
        while not is_done and j <= universe_local.count-1
          imprime("PAR",initial_local[i].bruta,"I",universe_local[j].bruta,"U",RULES_NAMES[:ires])

          universe_local.push comparison(initial_local[i],universe_local[j])
          initial_local[i],universe_local[j] = nil, nil
          universe_local = universe_local.compact
          initial_local = initial_local.compact
          imprime_conjuntos("NOVA CONFIGURAÇÃO",initial_local,"I",universe_local,"U")
          is_done = true if (initial_local.empty? and (universe_local.count < universe.count))

          if not is_done
            if resolution(initial_local,universe_local)
              is_done = true
              universe_local = []
            else
              puts "###### BACK [IN][IRES]######"
              initial_local, universe_local = [],[]
              reset_sets(initial_local,initial,universe_local,universe)
              imprime_conjuntos("VOLTOU PARA A CONFIGURAÇÃO",initial_local,"I",universe_local,"U")
              j = j.next
            end
          end
        end
        i = i.next
        j = i.next
      end
      puts "###### SAIU IRES ######"
      return is_done
    else
      puts "###### SAIU IRES ######"
      return false
    end
  end


  def self.comparison(sentence1, sentence2)
    sentence1_aux = sentence1
    sentence2_aux = sentence2
    sentence1.each do |el|
      sentence2.each do |el2|
        if Sentenca.opposites_literals?(el,el2)
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
        elsif Sentenca.same_literals?(el,el2)
          if el2.delete
            sentence2.update
          else
            sentence2_aux = nil
          end
        end
      end
    end
    if sentence1_aux.nil? and sentence2_aux.nil?
      return nil
    elsif sentence1_aux.nil?
      return sentence2
    elsif sentence2_aux.nil?
      return sentence1
    else
      return Sentenca.generate_disjunction_between(sentence1, sentence2)
    end
  end


  def self.imprime(msg,element1,tag1,element2,tag2,rule)
    puts "###### #{msg} - RULE: #{rule} ######"
    puts "#{element1}  [#{tag1}]"
    puts "#{element2}  [#{tag2}]"
  end

  def self.imprime_conjunto(msg,set,tag)
    puts "---------------#{msg}---------------"
    set.each_with_index{|el,index| puts "#{index}. #{el.bruta}     [#{tag}]"}
    puts "--------------------------------------------------------"
  end

  def self.imprime_conjuntos(msg,set1,tag1,set2,tag2)
    puts "---------------#{msg}---------------"
    set1.each_with_index{|el,index| puts "#{index}. #{el.bruta}     [#{tag1}]"}
    set2.each_with_index{|el,index| puts "#{index}. #{el.bruta}     [#{tag2}]"}
    puts "--------------------------------------------------------"
  end

  def self.reset_sets(initial_local, initial_global, universe_local, universe_global)
    initial_local.clear
    unless initial_global.empty?
      initial_local.push Sentenca.new(initial_global.first)
    end
    universe_local.clear
    universe_global.each{|el|universe_local.push Sentenca.new(el)}
  end

end