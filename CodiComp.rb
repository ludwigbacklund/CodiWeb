require_relative 'CodiGrammar.rb'
puts ARGV[0]
if ARGV[0]
  CodiWeb.new(ARGV[0]).go
else
  puts "Missing file argument"
end
