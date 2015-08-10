require_relative '../run_time/function_N.rb'
require_relative '../run_time/function_A.rb'
require_relative '../src/expressions.rb'
require_relative '../src/symbols.rb'
require_relative '../usr/append.rb'

$nil_list_symbol.token_value = 4
$cons_symbol.token_value = 5
$red_symbol.token_value = 6
$green_symbol.token_value = 7
$blue_symbol.token_value = 8



def $append_symbol.H(expr)
  inductive_arg1 = expr.content.arguments[0]
  case inductive_arg1.content.symbol.token
  when VARIABLE
    raise 'Handling Variables not implemented yet'
  when CHOICE
    raise 'Handling Choices not implemented yet'
  when FAIL
    expr.replace($fail_expression.content)
  when OPERATION
    inductive_arg1.H()
    expr.H()
  when 4  #nil_list
    inductive_arg2 = expr.content.arguments[1]
    case inductive_arg2.content.symbol.token
    when VARIABLE
      raise 'Handling Variables not implemented yet'
    when CHOICE
      raise 'Handling Choices not implemented yet'
    when FAIL
      expr.replace($fail_expression.content)
    when OPERATION
      inductive_arg2.H()
      expr.H()
    when 4  #nil_list
      # nil_list
      rhs = Box.new(Application.new($nil_list_symbol,[]))
      expr.replace(rhs.content)
    when 5  #cons
      # cons(_v1,_v2)
      rhs = Box.new(Application.new($cons_symbol,[expr.content.arguments[1].content.arguments[0],expr.content.arguments[1].content.arguments[1]]))
      expr.replace(rhs.content)
    end
  when 5  #cons
    # cons(z,append(zs,ys))
    rhs = Box.new(Application.new($cons_symbol,[expr.content.arguments[0].content.arguments[0],Box.new(Application.new($append_symbol,[expr.content.arguments[0].content.arguments[1],expr.content.arguments[1]]))]))
    expr.replace(rhs.content)
  end
  expr
end




def $main_symbol.H(expr)
  # append(cons(red,nil_list),cons(green,nil_list))
  rhs = Box.new(Application.new($append_symbol,[Box.new(Application.new($cons_symbol,[Box.new(Application.new($red_symbol,[])),Box.new(Application.new($nil_list_symbol,[]))])),Box.new(Application.new($cons_symbol,[Box.new(Application.new($green_symbol,[])),Box.new(Application.new($nil_list_symbol,[]))]))]))
  expr.replace(rhs.H().content)
  expr
end


def main
  main_expr = Box.new(Application.new($main_symbol,[]))
  main_expr.N()
end
