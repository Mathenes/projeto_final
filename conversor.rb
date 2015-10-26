#encoding: UTF-8
class Conversor

  require './sentenca.rb'
  require './binary_tree.rb'
  require 'pry'

  def self.executa
    #if __FILE__ == $0
      print "Insira a senteça: "
      sentenca_bruta = gets.strip.delete(" ")

      sentenca = Sentenca.new(sentenca_bruta)

      #--------------------------------------

      proposicoes = []
      operadores = []
      negacoes = []
      prioridade_atual = 0
      prioridade_fechada = nil
      node = nil

      sentenca.classificada.each do |el|

        #Se o elemento for um PARÊNTESE
        if el.instance_of? Parentese
          if el.is_abre_parentese?

            #Incrementa a prioridade
            prioridade_atual += 1

            el.prioridade = prioridade_atual
            puts el

          elsif el.is_fecha_parentese?

            prioridade_fechada = prioridade_atual
            prioridade_atual -= 1

            #Tem algum operador com a mesma prioridade do parentese que foi fechado que não tenha pai?
            aux = operadores.find {|el| el.element.prioridade_parentese == prioridade_fechada}
            if aux and !aux.father

              #Tem algum operador que tenha prioridade imediatamente inferior?
              #caso de exemplo: a -> (b ∧ c) --- quando o fecha parênteses é lido
              aux2 = operadores.find {|el| el.element.prioridade_parentese == prioridade_fechada - 1}
              if aux2
                #insere como filho da direita
                aux2.right_insert aux

                #remove operador aux do conjunto porque o mesmo acabou de ganhar um pai
                operadores.delete aux
              end

            end
          end
        else

          el.prioridade_parentese = prioridade_atual
          puts el
          node = BinaryTree::Node.new(el)

          #---------------------------------------------------------------------------------------------------
          #Se o elemento for uma PROPOSIÇÃO
          if el.instance_of? Proposicao

            # (~a&b)
            # (~~~a&b)
            # (a&~b)

            #Tem algum negacao com a mesma prioridade?
            #caso de exemplo: ... ∧ b --- quando já foi lido o operador e o elemento da direita é lido depois
            aux = negacoes.find {|el| el.element.prioridade_parentese == prioridade_atual}
            if aux
              #é inserido como filho da direita
              aux.right_insert node
            else

              #Tem algum operador com a mesma prioridade?
              #caso de exemplo: ... ∧ b --- quando já foi lido o operador e o elemento da direita é lido depois
              aux = operadores.find {|el| el.element.prioridade_parentese == prioridade_atual}
              if aux
                #é inserido como filho da direita
                aux.right_insert node

              else
                #Guarda a proposição no conjunto porque não pode ser feito nada com ela no momento
                #caso de exemplo: a -> (b ... --- quando a proposicão do lado esquerdo é lida mas não foi lido o operador
                proposicoes.push node

              end
            end

          #--------------------------------------------------------------------------------------------------
          #Se o elemento for um OPERADOR LÓGICO
          else

            # ~(a&b)
            # (~(a&b)->c)
            # (a->~(b&c))
            # (~a&b)
            # (a->~(a&b))

            # (~~~a&b)
            # a->~b
            if el.is_negacao?
              aux = proposicoes.find {|el| el.element.prioridade_parentese == prioridade_atual}
              if aux

                #insere como filho da direita
                aux.right_insert node
              else
                #(~a&b)
                #insere o operador no conjunto
                negacoes.push node
              end
            end

            #Tem alguma proposição com a mesma prioridade?
            #caso de exemplo: a -> ... --- quando o operador é lido, sabemos que anteriormente foi lida uma proposição
            aux = proposicoes.find {|el| el.element.prioridade_parentese == prioridade_atual}
            if aux

              #insere como filho da esquerda
              node.left_insert aux

              #remove a proposição aux do conjunto porque a mesma acabou de ganhar um pai
              proposicoes.delete aux

              #insere o operador no conjunto
              operadores.push node

            else

              # (~(a&b)->c)
              # (~~a&b)
              #Tem alguma negação sem pai?
              aux  = negacoes.find {|el| el.element.prioridade_parentese == prioridade_atual }
              if aux

                #insere como filho da esquerda
                node.left_insert aux

                #insere o operador no conjunto
                operadores.push node

              else
                #Tem algum operador que tenha prioridade imediatamente superior?
                #caso de exemplo: ... b) -> c --- quando o operador é lido depois de um fecha parênteses, ou seja,
                #depois de um conjunto de cláusulas
                aux = operadores.find {|el| el.element.prioridade_parentese == prioridade_atual + 1}
                if aux

                  #insere como filho da esquerda
                  node.left_insert aux

                  #remove operador aux do conjunto porque o mesmo acabou de ganhar um pai
                  operadores.delete aux

                  #insere o operador no conjunto
                  operadores.push node

                end
              end
            end

          end
        end
      end

      root = return_root(node)
      binding.pry
    #end
  end

  def self.return_root(node)
    aux = node
    while aux.father != nil
      aux = aux.father
    end
    aux
  end

end