#!/usr/bin/ruby
# Code for analyzing 18,000+ class names


fb = File.readlines("FBclasses.txt").
  map(&:strip).
  map{|c| c.sub('.h','').gsub(/[_-]/,'') }

analytes = fb.map do |c| 
  Hash[
    :prefix, (c.match(/^_?([A-Z]*)[A-Z][a-z]/) || [])[1],
    :class_parts, c.sub(/#{$1}/,'').split(/([A-Z]{1})/).reject(&:empty?).each_slice(2).map(&:join)
  ]
end.merge

parts = analytes.reduce([]) do |parts, a|
  #parts | a[:class_parts]  
  parts << a[:class_parts]  
end.sort.uniq

ns_parts_counts = analytes.reduce({}) do |ag,a|
  ag[a[:prefix]] ||= []
  ag[a[:prefix]] << a[:class_parts].size
  ag 
end

parts_empty = Hash[ parts.zip(Array.new(parts.size, [])) ]

parts_positions = analytes.reduce( parts_empty ) do |pos, a|
  a[:class_parts].each_with_index do |part, idx|
    pos[part] << idx
  end
  pos
end

# parts_positions['Component'].reduce(:+)/parts_positions['Component'].size.to_f
# parts_positions['Component'].group_by(&:itself).values.max_by(&:size).first

parts_positions = parts.reduce({}) do |pos, part|
  pos[part] ||= []
  pos[part] << analytes
end

