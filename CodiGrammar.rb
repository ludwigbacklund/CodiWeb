require_relative "parse.rb"
require_relative "CodiLogic.rb"
class CodiWeb
  attr_accessor :variable_list

  def initialize(file)
    @file = file
    @ruleparser = Parser.new("CodiWeb") do
      token(/\s/)
      token(/\d+/) { |x| x.to_i }
      token(/(\w+-\w+|\w+|"{1}.+?"{1})/) { |x| x }
      token(/(==|<=|>=|<|>|!=)/) { |x| x }
      token(/./) { |x| x }

      start :begin do
        match(:stmt_list) { |a| a.eval }
      end


      rule :create do
        match("create", :pre_def_obj, :stmt_list, "/", "create") { |_, a, b| Create.new(a, b) }
      end

      rule :loop do
        match("create_multiple", :num, :pre_def_obj, :var, :stmt_list, "/", "create_multiple") { |_, a, b, c, d, _| Create_Multiple.new(a, b, c, d) }
      end

      rule :pre_def_obj do
        match("link") { |_| Link.new() }
        match("paragraph") { |_| Paragraph.new }
        match("title") { |_| Title.new }
        match("image") { |_| Image.new() }
      end

      rule :if_stmt do
        match("if", :expr, :stmt_list, "/", "if") {|_, a, b, _| If.new(a, b)}
      end

      rule :expr do
        match(:comp_operation) { |a| a }
      end

      rule :stmt_list do
        match(:stmt_list, :stmt){ |a, b| Stmt_list.new(a, b) }
        match(:stmt) {|a| Stmt.new(a) }
      end

      rule :stmt do
        match(:loop) { |a| a }
        match(:construction) { |a| a }
        match(:operation) { |a| a }
        match(:comp_operation) { |a| a }
      end

      rule :comp_operation do
        match(:comp_operation, "and", :comparison) { |a, b, c| ExtComparison.new(a, b, c) }
        match(:comp_operation, "or", :comparison) { |a, b, c| ExtComparison.new(a, b, c) }
        match(:comparison) { |a| a }
      end

      rule :comparison do
        match(:var, :comp_operator, :value) { |a, b, c| Comparison.new(a, b, c) }
      end

      rule :comp_operator do
        match("==") { |a| a }
        match("!=") { |a| a }
        match(">=") { |a| a }
        match("<=") { |a| a }
        match(">") { |a| a }
        match("<") { |a| a }
      end

      rule :function do
        match("def", :func_name, "(", :var_list, ")", :stmt_list, "/", "def") { |_, a, _, b, _, c| Function.new(a, c, b) }
        match("def", :func_name, :stmt_list, "/", "def") { |_, a, b| Function.new(a, b) }
      end

      rule :func_name do
        match(/\w+?/) { |a| a }
      end

      rule :function_call do
        match(:func_name, ".", "call", "(", :value_list, ")") { |a, _, _, _, b|  FunctionCall.new(a, b) }
        match(:func_name, ".", "call") { |a, _, _| FunctionCall.new(a) }
      end
      rule :construction do
        match(:function_call) { |a| a }
        match(:function) { |a| a }
        match(:loop) { |a| a }
        match(:if_stmt) { |a| a }
        match(:create) { |a| a }
        match(:assignment){|a| a}
      end

      rule :assignment do
        match(:var, "=", :value) { |var, _, value| Assignment.new(var, value) }
        match(:var, "=", :operation) { |a, _, b| Assignment.new(a, b) }
      end

      rule :operation do
        match(:num) { |a| a }
        match(:operation, :math_operation, :num) { |a, b, c| Operation.new(a, b, c) }
      end

      rule :math_operation do
        match("*") { |a| Multiplier.new }
        match("/") { |a| Divider.new }
        match("+") { |a| Adder.new }
        match("-") { |a| Subtractor.new }
      end

      rule :value do
        match(:num) { |a| a }
        match(:string) {|a| a }

        match(:var){|a| a }
      end

      rule :string do
        match(/".+"/) {|a| a }
      end
      rule :var_list do
        match(:var) { |a| a }
        match(:var_list, ",", :var) { |a, _, b| MultVar.new(b, a) }
      end
      rule :value_list do
        match(:value_list, ",", :value) { |a, _, b| MultVar.new(b, a) }
        match(:value) { |a| a }
      end
      rule :var do
        match(:pre_def_var) {|a| a }
        match(/\w+?/) {|a| Var.define(a) }
      end

      rule :pre_def_var do
        match("url") { |a| Url.new(a) }
        match("text") { |a| Text.new(a) }
        match("path") { |a| Path.new(a) }
        match("color") { |a| Color.new(a) }
        match("position") { |a| Position.new(a) }
        match("bottom-left") { "left:5%;top:60%;" }
        match("bottom-middle") { "left:35%;top:30%;" }
        match("bottom-right") { "left:75%;top:60%;" }
        match("middle-left") { "left:5%;top:30%;" }
        match("middle-middle") { "left:35%;top:30%;" }
        match("middle-right") { "left:75%;top:30%;" }
        match("top-left") { "left:5%;top:5%;" }
        match("top-middle") { "left:35%;top:5%;" }
        match("top-right") { "left:75%;top:5%;" }
      end

      rule :num do
        match(Integer) { |a| a }
      end

    end

  end

  def go
    block = ""
    File.foreach(@file) do |line|
      p line
      block += line
    end
    puts "CodiWeb Constructed the file => #{@ruleparser.parse block}"
  end

end

