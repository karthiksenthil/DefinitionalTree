require_relative './definitional_tree.rb'
require_relative './pseudo_replace.rb'

# class to represent the set rules obtained as output of compile procedure
# lhs -> Box wrapping an Expression
# rhs -> Box wrapping an Expression
class Rule
	attr_accessor :lhs,:rhs

	def initialize(lhs,rhs)
		@lhs = lhs
		@rhs = rhs
	end

	def show
		return @lhs.show() + ' = ' + @rhs.show()
	end

	def ==(another_rule)
		return self.lhs.content == another_rule.lhs.content && self.rhs.content == another_rule.rhs.content
	end

end

# extending the Application and Variable classes for compile procedure
# to handle the Leaf node case

class Application < Expression

	def generate_H(lhs_pattern)
		output_lhs = H.new(lhs_pattern)
		output_rhs = nil
		# identify the leading symbol of RHS 
		leading_symbol = self.symbol
		if leading_symbol.token == OPERATION # case 2.1 i.e operator rooted
			output_rhs = H.new(self)
		elsif leading_symbol.token >= CONSTRUCTOR # case 2.2 i.e constructor rooted 
			output_rhs = self
		end

		output = [Rule.new(Box.new(output_lhs),Box.new(output_rhs))]
		
		return output
	end

end

class Variable < Expression

	def generate_H(lhs_pattern)
		var_type = self.type
		output = []
		if var_type=="*" # include all the constructors for a Variable of any type
			constructors = $constructors_hash.values.flatten
		else
			constructors = $constructors_hash[var_type]
		end

		# l_prime -> r_prime where r_prime is expr when r is replaced by a constructor
		if !constructors.nil?
			constructors.each do |constructor|
				constructor_expr = nil
				replaced_args = lhs_pattern.arguments.map{ |a|
					if a.content == self
						# replace constructor which an expression built using constructor
						arity = constructor.arity
						
						args = []
						(1..arity).each do |i|
							args << make_variable("_v"+i.to_s,"temporary_variable")
						end

						constructor_expr = Box.new(Application.new(constructor,args))
						constructor_expr
					else
						a
					end
				}
				replaced_patt = Application.new(lhs_pattern.symbol,replaced_args)
				output_lhs = H.new(replaced_patt)
				output_rhs = constructor_expr

				output += [Rule.new(Box.new(output_lhs),output_rhs)] 
			end
		end

		
		output += [Rule.new(Box.new(H.new(lhs_pattern)),Box.new(H.new(self)))]

		return output
	end

end


# implementation of the 'COMPILE' procedure for a definitional tree

class Branch < DefTreeNode

	#(1) to handle the case when the node is a Branch
	def compile
		output = []
		self.children.each do |child|
			output += child.compile()
		end

		inductive_var = self.variable

		# replace RHS of the branch, replace the inductive_var by H(inductive_var)
		# self.pattern is a Box
		# replaced_branch_patt = self.pattern.content.replace(inductive_var)  -- deprecated method
		# H(xs+ys) = H(H(xs)+ys)

		replaced_branch_patt = self.pattern.content.pseudo_replace(inductive_var.content)
		output += [Rule.new(Box.new(H.new(self.pattern.content)),Box.new(H.new(replaced_branch_patt)))]
		return output		
	end

end

ABORT = CONSTRUCTOR
class Exempt < DefTreeNode

	#(3) to handle the case when the node is Exempt
	def compile
		abort_symbol = XSymbol.new("abort",0,ABORT)
		if $constructors_hash["unknown"].nil?
			$constructors_hash["unknown"] = [abort_symbol]
		else
			$constructors_hash["unknown"] += [abort_symbol]
		end
		
		abort_expr = Box.new(Application.new(abort_symbol,[]))
		output = [Rule.new(Box.new(H.new(self.pattern)),Box.new(H.new(abort_expr)))]
		return output
	end

end

class Leaf < DefTreeNode

	#(2) to handle the case when the node is a Leaf(Rule)
	def compile
		rule_rhs = self.expression.content  # self.expression is wrapped in a Box
		output = []
		output += rule_rhs.generate_H(self.pattern.content) #self.pattern is also wrapped in a Box

		return output

	end

end

