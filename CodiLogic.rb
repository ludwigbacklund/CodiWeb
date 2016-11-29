require 'rubygems'
@@html = nil

class Begin
  attr_reader :html, :css

  def initialize()
    @htmlname = "Result.html"
    @@html = File.new("Result.html", "w")
    IO.copy_stream('template.html', @htmlname)
    return @@html
  end

  def html
    return @htmlname
  end
end
@@html = Begin.new().html()
class VariableList
  attr_reader :list

  def initialize()
    @list = [{}]
  end

  def add(var)
    @list[@@scope_counter][var.name] = var.value
    @list
  end

  def increase()
    if @@scope_counter == 0
      @list << {}
      @@scope_counter = @list.length - 1
    end
  end

  def clear()
    @list[@@scope_counter].clear()
  end

  def findValue(var)
    @list.each do |varObj|
      if varObj.name == var
        return varObj.value
      end
    end
    return false
  end

  def findVar(var)
    @list.each do |varObj|
      if varObj.name == var
        return varObj
      end
    end
    return false
  end
end

@@variableList = VariableList.new()
@@scope_counter = 0

class MultVar
  def initialize(var, multvar = nil)
    @var = var
    @varlist = multvar if multvar
    @variables = []
  end

  def eval()
    @varlist.eval if @varlist
    @var.eval
  end

  def variables()
    @variables.clear
    if @varlist.class == MultVar
      @variables += @varlist.variables
    else
      @variables << @varlist
    end
    if @var.class == MultVar
      @variables += @var.variables
    else
      @variables << @var
    end
    @variables.reverse
  end
end
class Var
  attr_reader :value, :name, :type

  def initialize(name)
    @name = name
    @value = nil
    @type = nil
  end

  def variables
    return [self]
  end

  def Var.define(name)
    var = @@variableList.list[@@scope_counter][name]
    if var
      return var
    else
      Var.new(name)
    end

  end

  def update(value)
    @value = value
    @type= value.class
  end

  def eval()
    return self
  end

  def print
    return @value
  end
end
class Url < Var
  def update(value)
    if value.class == String
      @type = "pre_def_var"
      @value = 'href= '+ value
    elsif value.class == List
      @type = "pre_def_var"
      @value = value
    end

  end

  def Url.define(name)
    url = @@variableList.list[@@scope_counter][name]
    if url
      return url
    else
      Url.new(name)
    end
  end
end

class Text < Var
  def update(value)
    @type = "text"
    value.gsub!(/\"/, "")
    @value = value
  end
end
class Create
  attr_reader :value

  def initialize(obj, stmt_list)
    @value = obj
    @obj = obj
    @stmt_list = stmt_list
  end

  def eval
    scope_before = @@scope_counter
    @@variableList.increase
    scope_after = @@scope_counter
    @stmt_list.eval
    @obj.update(@stmt_list)
    @obj.eval()
    @@scope_counter = 0 if scope_before != scope_after
    @stmt_list
  end

  def variables
    @stmt_list.variables
  end
end

class Stmt_list
  attr_reader :variables

  def initialize(obj, stmt_list = nil)
    @stmt = obj
    @stmt_list = stmt_list
    @variables = []
  end

  def eval()
    @stmt.eval() unless @stmt.class == Function
    stmtVariables = retrieve_values(@stmt.variables)
    if @stmt_list
      @stmt_list.eval unless @stmt_list.class == Function
    end
    true
  end

  def retrieve_values(stmt_list)
    variables = []
    if stmt_list.class == Array
      stmt_list.each { |x| variables << x }
    else
      variables << stmt_list
    end
    return variables
  end

  def reset_values()
    @variables.clear
  end

end

class Stmt
  attr_reader :variables

  def initialize(obj)
    @stmt = obj
    @variables = []
  end

  def eval()
    @stmt.eval() unless @stmt.class == Function
    retrieve_values(@stmt.variables)
    true
  end

  def retrieve_values(stmt_list)
    variables = []
    variables << stmt_list
    return variables
  end

  def reset_values()
    @variables.clear
  end

end
class Assignment
  attr_reader :value

  def initialize(var, value)
    @var = var
    @value = value
  end

  def eval()
    if @value.class == Var
      @var.update(@@variableList.list[@@scope_counter][@value.name])
    elsif @value.class == String
      @var.update(@value)
    elsif @value.class == Operation
      @var.update(@value.eval)
    else
      @var.update(@value)
    end
    @@variableList.add(@var)
    @var
  end

  def variables
    return [@var]
  end
end

class Predefined_object
  def initialize()
    @content = ""
    @htmlpage = File.open(@@html)
    @css = 'style='
    @html = ""
    @stmt_list = nil
  end

  def add_css(value)
    @css += value
  end

  def add_html(value)
    @html += value
  end

  def add_content(value)
    @content += value
  end

  def eval()
    l = @@variableList.list[@@scope_counter]
    l.each do |key, value|
      if @attributes.has_key?(key)
        add_css(value) if @attributes[key] == "css"
        add_html(value) if @attributes[key] == "html"
        add_content(value) if @attributes[key] == "content"
      end
    end
    build
    true
  end

  def build()
    final = @pre_tag.insert(-2, +" " + @html+ " " + @css) + @content + @end_tag
    fil = File.open(@@html)
    read = fil.read
    topSpan = findWriteLoc(read)
    temp = (read).insert(topSpan, "\n"+final)
    File.write(@@html, temp)
    fil.close
  end

  def update(stmt_list)
    @stmt_list = stmt_list
  end

  def findWriteLoc(string)
    body_index = string.index("<body>")
    if body_index
      return body_index + 6
    else
      raise Exception.new("Invalid Template file, make sure <body> is included")
    end
  end
end

class Link < Predefined_object
  def initialize
    super
    @attributes = {"url" => "html", "position" => "css", "text" => "content"}
    @pre_tag = "<a >"
    @end_tag = "</a>"
  end

  def clone
    Link.new()
  end
end


class Image < Predefined_object
  def initialize
    super
    @attributes = {"path" => "html", "position" => "css"}
    @pre_tag = "<img >"
    @end_tag = "</img>"
  end

  def clone
    Image.new()
  end
end

class Paragraph < Predefined_object
  def initialize
    super
    @attributes = {"text" => "content", "position" => "css", "color" => "css"}
    @pre_tag = "<p >"
    @end_tag = "</p>"
  end

  def clone
    Paragraph.new
  end
end

class Title < Predefined_object
  def initialize
    super
    @attributes = {"text" => "content", "position" => "css", "color" => "css"}
    @pre_tag = "<h1 >"
    @end_tag = "</h1>"
  end

  def clone
    Title.new
  end
end
class Path < Var
  def update(value)
    @type = "pre_def_var"
    @value = "src=" + value
  end

  def Path.define(name)
    var = @@variableList.list[@@scope_counter][name]
    if var
      return var
    else
      Path.new(name)
    end
  end
end

class If
  def initialize(expr, stmt_list)
    @expr = expr
    @stmt_list = stmt_list
    @comparison_return = false
  end

  def eval()
    @comparison_return = @expr.eval
    if @comparison_return
      @stmt_list.eval
    else
      @expr
    end
  end

  def variables
    if @comparison_return
      @stmt_list.variables
    else
      []
    end
  end
end

class Comparison
  def initialize(var, comp_oper, value)
    @var = var
    @comp_oper = comp_oper
    @value = value
  end

  def eval
    var = @@variableList.list[@@scope_counter][@var.name]
    if var
      if @comp_oper == "=="
        return var == @value
      elsif @comp_oper == "!="
        return var != @value
      elsif @comp_oper == ">="
        return var >= @value
      elsif @comp_oper == ">"
        return var > @value
      elsif @comp_oper == "<="
        return var <= @value
      elsif @comp_oper == "<"
        return var < @value
      end
    end
  else
    raise Exception.new("Undeclared Variable #{@var.name}")
  end
end
class ExtComparison
  def initialize(comp, comp_oper, comp2)
    @comp_one = comp2
    @extender = comp_oper
    @comp_list = comp
  end

  def eval
    if @extender == "or"
      expr1 = @comp_one.eval
      expr2 = @comp_list.eval
      bool = expr1 || expr2
      return bool
    end
    if @extender == "and"
      expr1 = @comp_one.eval
      expr2 = @comp_list.eval
      bool = expr1 && expr2
      return bool
    end
  end
end

class Create_Multiple
  def initialize(number, obj, var, stmt_list)
    @obj = obj
    @times = number
    @obj_list = []
    @var = var
    @stmt_list = stmt_list
  end

  def eval
    scope_before = @@scope_counter
    @@variableList.increase
    scope_after = @@scope_counter
    obj_amount = @times
    obj_amount.times do
      @obj_list << @obj.clone
    end
    rawStmt = @stmt_list
    @obj_list.each_with_index do |obj, index|
      @stmt_list = rawStmt
      variable = Assignment.new(@var, index+1)
      variable.eval
      @stmt_list.eval
      obj.update(@stmt_list)
      obj.eval()
    end
    @@scope_counter = 0 if scope_before != scope_after
    return true
  end

  def variables
    @stmt_list.variables
  end
end

class Position < Var
  def update(value)
    @type = "css"
    @value = "position:absolute;#{value}"
  end
end


class Color < Var
  def update(value)
    @type = "css"
    value.gsub!(/\"/, "")
    @value = "color:#{value};"
  end
end

class Function
  attr_reader :name, :status, :variables, :value

  def initialize(name, stmt_list, varlist = nil)
    @name = name
    @stmt_list = stmt_list
    @variables = varlist
    @value = self
    @@variableList.add(self)
    true
  end

  def variables
    return @variables.variables if @variables
    return [] if not @variables
  end

  def eval
    @stmt_list.eval
  end
end

class FunctionCall
  def initialize(name, varlist = nil)
    @name = name
    @varlist = varlist if varlist
  end

  def eval
    l = @@variableList.list[@@scope_counter]
    @@variableList.increase
    l.clone.each do |key, value|
      if key == @name
        function_variables = l[key]
        if (@varlist && function_variables) && @varlist.variables.length == function_variables.variables.length
          @varlist.variables.each_with_index do |x, i|
            Assignment.new(function_variables.variables[i], x).eval
          end
        elsif not @varlist

        elsif @varlist.variables.length != function_variables.variables.length
          raise Exception.new("Wrong number of arguments for function #{function_variables.name}")
        end
        return function_variables.eval
      end
    end
  end
end

class Operation
  attr_reader :variables

  def initialize(operation, math_operation, value)
    @value, @math_operation, @operation = value, math_operation, operation
    @variables = []
  end

  def variables
    @variables << @value
    if @math_operation
      @variables << @math_operation
    end
    if @operation
      @variables += @operation.variables if @operation.class == Operation
      @variables << @operation if @operation.class == Fixnum
    end
    return @variables
  end

  def eval
    variables()
    @math_operation.set_values(@operation.eval, @value) if @operation.class == Operation
    @math_operation.set_values(@operation, @value) if @operation.class == Fixnum || @operation.class == Float
    @math_operation.eval
  end
end

class MathExpr
  def initialize
    @l_h = nil
    @r_h = nil
  end

  def set_values(l_h, r_h)
    @l_h, @r_h = l_h, r_h
  end
end

class Multiplier < MathExpr
  def eval
    return @l_h * @r_h
  end
end

class Divider < MathExpr
  def eval
    return @l_h / @r_h
  end
end

class Adder < MathExpr
  def eval
    return @l_h + @r_h
  end
end

class Subtractor < MathExpr
  def eval
    return @l_h - @r_h
  end
end