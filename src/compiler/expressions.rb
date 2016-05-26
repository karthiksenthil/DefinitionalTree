require_relative './symbols.rb'

# Basic building block classes for the nodes of tree

# a structure to trace each and every replacement
# structure of stack element :
# {box_of_redex, content_of_redex, content_of_contractum}
$replacement_stack = []  

# a wrapper class around Expressions
class Box
	attr_accessor :content #content is an Expression object

	def initialize(content)
		@content = content
	end

	def replace(new_content) # new content should be content of new Box object(contractum) only
		replace_record = {redex_box: self, redex_content: self.content, contractum_content: new_content}
		$replacement_stack.push(replace_record) if !$backtrack
		# Log.write(sprintf("R %s -> %s\n",@content.show,new_content.show)) if $trace
		@content = new_content
	end

	# the method to replace/undo steps during backtrack stage(no push to stack)
	def undo(new_content)
		Log.write(sprintf("U %s -> %s\n",self.show,new_content.show)) if $trace
		self.content = new_content
	end

	# showing a Box
	def show
		return @content.show()
	end

	def H
		# H is defined only for OPERATION and CHOICE symbols
		if self.content.symbol.token != OPERATION && self.content.symbol.token != CHOICE
			raise "H is not defined on a non-operation rooted expression"
		else
			self.content.symbol.H(self)
		end
	end

	def ==(another_box)
		if another_box.class == Box
			return self.content == another_box.content
		else
			return false
		end
	end

	# function to check variant
	def is_variant?(another_box)
		if another_box.class == Box
			return self.content.is_variant?(another_box.content)
		else
			return false
		end
	end

end


class Expression

	# abstract function
	# Functionality : replace an expression by an executable expression
	def replace
	end

	# abstract function
	# Functionality : check if expression is a constructor-rooted expression
	def construct_expr?
	end

end

# Class to denote variables
class Variable < Expression
	attr_accessor :symbol,:type

	# create a varible with its name
	# Params : symbol
	# Return : Variable
	def initialize(symbol,type)
		@symbol = symbol # the printable representation of variable
		@type = type # tags the Variable with its type
	end

	def show
		return @symbol.show()
	end

	# check if variable is a constructor-rooted expression
	# Return : true(boolean)
	def construct_expr?
		return true
	end

	def ==(another_variable)
		if another_variable.class == Variable
			self.symbol == another_variable.symbol
		else
			false
		end
	end

	# two variables are always similar (independence of type?)
	def is_variant?(another_variable)
		if another_variable.class == Variable
			true
		else
			false
		end
	end

end

# global function to make any Variable object
def make_variable(name,type)
	sym = Variable_symbol.new(name,0)
	return Box.new(Variable.new(sym,type)) # wrap the Variable in a Box
end


# Class to denote applications
class Application < Expression
  attr_accessor :symbol, :arguments
  
  # create an application with a root-symbol and arguments
  # Params : symbol(XSymbol), arguments(array of Expression/XSymbol)
  # Return : Application
  def initialize(symbol,arguments)
    @symbol = symbol
    @arguments = arguments
  end
  
  # give a representation of an application
  # for example, xs ++ ys ==> ++(xs,ys)
  # Return : output(string)
  def show
  	output = symbol.name+"("
  	if !@arguments.nil?
  		@arguments.each do |arg|
  			output += arg.show()+","
  		end
  	end
  	
  	if output[-1] == ',' # to remove the last comma
  		output[-1] = ''
  		output += ")"
		elsif output[-1] == '(' # case to remove '(' if Application has no arguments
			output[-1] = ''
  	end
	
		return output
  end

  # check if variable is a constructor-rooted expression
	# Return : true/false(boolean)
  def construct_expr?
  	return self.symbol.token >= CONSTRUCTOR && self.arguments.map{|a| a.construct_expr?}.all? 
  end

  def ==(another_application)
  	if another_application.class == Application
  		# temporary code to make current unit test pass
  		# args_equality = []
  		# (0..self.arguments.length-1).each do |i|
  		# 	args_equality << self.arguments[i].content == another_application.arguments[i].content
  		# end 
  		# return self.symbol == another_application.symbol && args_equality

  		######### IMPORTANT #########
  		# old code, revert to this after coding compile.rb  
  		return self.symbol == another_application.symbol && self.arguments == another_application.arguments
  	else
  		false
  	end
  end

  # moving to Box
  # def H
  # 	self.symbol.H(self)
  # end

  # check if one Application(Expression) is similar to another
  def is_variant?(another_application)
  	if another_application.class == Application
  		return false if self.arguments.count != another_application.arguments.count

  		args_similarity = []
  		self.arguments.zip(another_application.arguments).each do |a,b|
  			args_similarity << a.is_variant?(b)
  		end
  		# same symbol name
  		return self.symbol == another_application.symbol && args_similarity.all?
  	else
  		return false
  	end
  end

end

# global expressions like fail_expression
$fail_expression = Box.new(Application.new($fail_symbol,[]))



# Pattern is an application meeting certain conditions
class Pattern < Application
	
	# perform a sanity check on a new Pattern
	# if error raise corresponding exception
	# Params : application(Application)
	def initialize(application)
		if application.symbol.token != OPERATION 
			raise "Root symbol of Pattern is not an operator"
		else
			application.arguments.each do |arg|
				if !arg.construct_expr?
					raise "Non root symbol of Pattern is not a variable or a constructor rooted symbol"
				end
			end
		end
	end


end

# Data-structure to store the constructors of a type
# Key : data type
# Values : array of XSymbols(constructors)
$constructors_hash = {}


### APPENDIX ###
# code to test sanity check in Pattern
=begin
append_symbol = XSymbol.new("append",2,:oper)
nil_list_symbol = XSymbol.new("[]",0,:ctor)
cons_symbol = XSymbol.new(":",2,:oper)
xs = Variable.new("xs")
ys = Variable.new("ys")
z = Variable.new("z")
zs = Variable.new("zs")
lhs2 = Application.new(append_symbol,[Application.new(cons_symbol,[z,zs]),ys])
p = Pattern.new(lhs2)
=end
