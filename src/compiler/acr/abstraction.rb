# class hierarchy to represent abstraction of H function
# produced by generate_h procedure

require_relative '../expressions.rb'

class Abstract_H

end

$inductive_arg_counter = 0
class Case_H < Abstract_H
	# inductive_var_path -> path to the inductive variable for the case
	# case_entries -> list of Entry objects
	attr_accessor :inductive_var_path, :case_entries

	def initialize(ind_var_path,entries)
		@inductive_var_path = ind_var_path
		@case_entries = entries
	end

	def print_in_ruby(indent=0)
		$inductive_arg_counter += 1
		inductive_arg_str = "inductive_arg"+$inductive_arg_counter.to_s
		
		output = ''
		output += print_spaces(indent)+inductive_arg_str+" = expr"+build_path(@inductive_var_path)+"\n"
		output += print_spaces(indent)+"case "+inductive_arg_str+".content.symbol.token"+"\n"

		@case_entries.each do |entry|
			output += entry.print_in_ruby(indent)
		end

		output += print_spaces(indent)+"end"+"\n"
		return output

	end

end

class RHS_Replace_H < Abstract_H
	# replace_expression -> RHS expression used to replace current expr
	# replace_pattern -> the pattern on LHS which is replaced by expression
	# replace_type -> can take values "constructor" or "operation"
	attr_accessor :replace_expression, :replace_pattern, :replace_type

	def initialize(expression,pattern,type)
		@replace_expression = expression
		@replace_pattern = pattern
		@replace_type = type
	end

	def print_in_ruby(indent=0)
		output = print_spaces(indent)+"# "+@replace_expression.show()+"\n"
		output += print_spaces(indent)+"rhs = "+@replace_expression.print_in_ruby(indent,replace_pattern)+"\n"
		if @replace_type == "constructor"
			output += print_spaces(indent)+"expr.replace(rhs.content)"+"\n"
		elsif @replace_type == "operation"
			output += print_spaces(indent)+"expr.replace(rhs.H().content)"+"\n"
		end
		return output
	end

end


class Application < Expression

	def print_in_ruby(indent=0,pattern)
		output = "Box.new(Application.new("
		output += "$"+self.symbol.show()+"_symbol,["
		output +=
		self.arguments.map{|arg|
			arg.content.print_in_ruby(indent,pattern)
		}.join(",")

		output += "]))"
		return output
	end

end

class Variable < Expression

	def print_in_ruby(indent=0,pattern)
		path = pattern.find_path(self)
		output = "expr"+build_path(path)
		return output
	end

end

## some new utilities , move to utilities.rb later ##

def build_path(path)
	output = ''
	path.each do |i|
		output += '.content.arguments['+(i-1).to_s+']' 
	end
	return output
end



###################### Meta expression code #########################
=begin
class Meta_expression
	attr_accessor :symbol, :arguments # arguments can be path to varibles or another meta-expression

	def initialize(sym,args)
		@symbol = sym
		@arguments = args
	end

	def print_in_ruby(indent=0)
		output = "Box.new(Application.new("
		output += "$"+@symbol.show()+"_symbol,["
		output +=
		@arguments.map { |arg|
			if arg.class == Array
				"expr"+build_path(arg)
			else
				arg.print_in_ruby(indent)
			end  
		}.join(",")

		output += "]))"
		
	end

end


class Variable < Expression

	def meta_expr_format(pattern)
		path = pattern.find_path(self)
		return path
	end

end

class Application < Expression

	def meta_expr_format(pattern)
		meta_expr_sym = self.symbol
		meta_expr_args = []

		self.arguments.each do |arg|
			meta_expr_args << arg.content.meta_expr_format(pattern)
		end

		meta_expr = Meta_expression.new(meta_expr_sym,meta_expr_args)
		return meta_expr
	end

end
=end