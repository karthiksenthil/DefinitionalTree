require_relative './definitional_tree.rb'
require_relative './replace.rb'

# implementation of the 'COMPILE' procedure for a definitional tree

def compile(def_tree)
	#(1) to handle the case when the node is a Branch
	if def_tree.class == Branch
		def_tree.children.each do |child|
			compile(child)		
		end

		inductive_var = def_tree.variable
		branch_patt = def_tree.pattern
		output = 'H(' + branch_patt.show() + ') = '

		# replace RHS of the branch, replace the inductive_var by H(inductive_var)
		replaced_branch_patt = branch_patt.replace(inductive_var)
		output += 'H(' + replaced_branch_patt.show() +')'

		print output+"\n"
	
	#(2) to handle the case when the node is a Leaf(Rule)
	elsif def_tree.class == Leaf
		rule_rhs = def_tree.expression
		output = ''
		# to handle the case when RHS of the rule is a pattern or symbol
		if rule_rhs.class == Application || rule_rhs.class == XSymbol
			# identify the leading symbol of RHS 
			leading_symbol = rule_rhs.class == Application ? rule_rhs.symbol : rule_rhs
			output = 'H(' + def_tree.pattern.show() + ') = '
			if leading_symbol.kind == :oper  # case (2.1) i.e. operator-rooted
				output += 'H(' + rule_rhs.show() +')'
			elsif leading_symbol.kind == :ctor	# case (2.2) i.e. constructor-rooted
				output += rule_rhs.show()
			end
			
								
		# to handle the case when the RHS of the rule is a variable
		elsif rule_rhs.class == Variable			
			var_type = "list" # hard-coded for the case of append.rb, alt -> rule_rhs.type ?
			constructors = @constructors_hash[var_type]

			if !constructors.nil?
				# l_prime -> r_prime where r_prime is expr when r is replaced by a constructor
				constructors.each do |constructor|
					replaced_args = def_tree.pattern.arguments.map{|a| 
						if a == rule_rhs
							constructor
						else
							a
						end
					}
					replaced_patt = Application.new(def_tree.pattern.symbol,replaced_args)
					output += 'H(' + replaced_patt.show() + ') = '
					output += constructor.show()+"\n" 
				end
			end

			output += 'H(' + def_tree.pattern.show() + ') = ' + 'H(' + rule_rhs.show() +')'

		end 
		print output+"\n"
		


	#(3) to handle the case when the node is Exempt 
	elsif def_tree.class == Exempt
		output = 'H(' + def_tree.pattern.show() + ') = abort'
		print output+"\n"
	end

end

# for the RHS of the branch, replace the inductive_var by H(inductive_var)
		# code fails when inductive_var occurs in nested arguments
=begin
		branch_patt_rhs = branch_patt.symbol.name+"("
  	branch_patt.arguments.each do |arg|
  		if arg == inductive_var
  			branch_patt_rhs += 'H('+arg.show()+'),'
  		else
  			branch_patt_rhs += arg.show()+","
  		end
  	end
  	# to remove the last comma
  	if branch_patt_rhs[-1] == ','
  		branch_patt_rhs[-1] = ''
  	end

  	output += 'H('+branch_patt_rhs+')'
=end