require 'rubygems'
require 'neography'

@neo = Neography::Rest.new

def create_person(name)
  @neo.create_node("name" => name)
end

def make_mutual_friends(node1, node2)
  @neo.create_relationship("friends", node1, node2)
  @neo.create_relationship("friends", node2, node1)
end

def degrees_of_separation(start_node, destination_node)
  paths =  @neo.get_paths(start_node, 
                          destination_node, 
                          {"type"=> "friends", "direction" => "in"},
                          depth=4, 
                          algorithm="allSimplePaths")
  paths.each do |p|
   p["names"] = p["nodes"].collect { |node| 
     @neo.get_node_properties(node, "name")["name"] }
  end
end

johnathan = create_person('Johnathan')
mark      = create_person('Mark')
phil      = create_person('Phil')
mary      = create_person('Mary')

make_mutual_friends(johnathan, mark)
make_mutual_friends(mark, phil)
make_mutual_friends(phil, mary)
make_mutual_friends(mark, mary)

degrees_of_separation(johnathan, mary).each do |path|
  puts "#{(path["names"].size - 1 )} degrees: " + path["names"].join(' => friends => ')
end

# RESULT
# 3 degrees: Johnathan => friends => Mark => friends => Phil => friends => Mary
# 2 degrees: Johnathan => friends => Mark => friends => Mary


def degrees_of_separation(start_node, destination_node)
  paths =  @neo.get_paths(start_node, 
                          destination_node, 
                          {"type"=> "friends", "direction" => "in"},
                          depth=4, 
                          algorithm="shortestPath")
  paths.each do |p|
   p["names"] = p["nodes"].collect { |node| 
     @neo.get_node_properties(node, "name")["name"] }
  end
end

# RESULT
# 2 degrees: Johnathan => friends => Mark => friends => Mary

require 'rubygems'
require 'neography'

def create_person(name)
  Neography::Node.create("name" => name)
end

johnathan = create_person('Johnathan')
mark      = create_person('Mark')
phil      = create_person('Phil')
mary      = create_person('Mary')

johnathan.both(:friends) << mark
mark.both(:friends) << phil
phil.both(:friends) << mary
mark.both(:friends) << mary

johnathan.all_simple_paths_to(mary).incoming(:friends).depth(4).nodes.each 
do |path|
  puts "#{(path.size - 1 )} degrees: " + path.map{|n| n.name }.join(' => friends => ')
end
# RESULT
# 3 degrees: Johnathan => friends => Mark => friends => Phil => friends => Mary
# 2 degrees: Johnathan => friends => Mark => friends => Mary

johnathan.shortest_path_to(mary).incoming(:friends).depth(4).nodes.each 
do |path|
  puts "#{(path.size - 1 )} degrees: " + path.map{|n| n.name }.join(' => friends => ')
end
# RESULT
# 2 degrees: Johnathan => friends => Mark => friends => Mary
