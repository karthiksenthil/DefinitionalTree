require_relative '../src/definitional_tree.rb'
require_relative '../src/compile.rb'

# Example to construct definitonal tree for the rules representing
# the append operation(on lists or arrays)

# Rules:
# General rule -> append xs ys
# 1. append [] ys = ys
# 2. append (z:zs) ys = z:(append zs ys)


# Symbols in the rules
$append_symbol = XSymbol.new("append",2,:oper)
$nil_list_symbol = XSymbol.new("[]",0,:ctor)
$cons_symbol = XSymbol.new(":",2,:ctor)

# methods/constructors to shorten code and better readability
def make_append(x,y)
	return Application.new($append_symbol,[x,y])
end

def make_nil
	return Application.new($nil_list_symbol,[])
end

def make_cons(x,y)
	return Application.new($cons_symbol,[x,y])
end

if $constructors_hash["list"].nil?
	$constructors_hash["list"] = [$nil_list_symbol,$cons_symbol]
else
	$constructors_hash["list"] += [$nil_list_symbol,$cons_symbol]
end

# Variables in the rules
$xs = Variable.new("xs","list")
$ys = Variable.new("ys","list")
$z = Variable.new("z","list")
$zs = Variable.new("zs","list")

# child1 i.e rule1 ; lhs = pattern and rhs = expression
lhs1 = make_append(make_nil,$ys)
rhs1 = $ys	
child1 = Leaf.new(lhs1,rhs1)

# child2 i.e rule2
# (z:zs) itself is another sub-pattern which is built using the : symbol
lhs2 = make_append(make_cons($z,$zs),$ys)
# similarly (append zs ys)
rhs2 = make_cons($z,make_append($zs,$ys))
child2 = Leaf.new(lhs2,rhs2)

# definitional tree for above rules

rootpatt = make_append($xs,$ys)
append_tree = Branch.new(rootpatt,$xs,[child1,child2])

# rules produced on running compile on append operation's definitional tree
$rules = append_tree.compile()

