require_relative './expressions.rb'
require_relative './exec_expressions.rb'


class Variable < Expression
	
	def replace(var)
		if self.name == var.name
			replaced_var = H.new(var)
			return Variable.new(replaced_var.show())
		else
			return self
		end
	end

end

class Application < Expression
	  
	def replace(var)
		args = @arguments.map { |a| a.replace(var)  }
		return Application.new(@symbol,args)
	end
 
end