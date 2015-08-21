#!/usr/bin/ruby
# Code for analyzing 18,000+ class names

require 'lingua/stemmer'

class Klassextant
  attr_reader :base, :analytes

  def initialize(filename="FBclasses.txt")
    klass_load(filename)
  end

  def analytes
    @analytes ||= @base.map do |c|
      Hash[
        :prefix, (c.match(/^_?([A-Z]*)[A-Z][a-z]/) || [])[1],
        :class_parts, c.sub(/#{$1}/,'').split(/([A-Z]{1,})/).reject(&:empty?).each_slice(2).map(&:join)
      ]
    end
  end

  def analyte_tree
    @analyte_tree ||= @analytes.reduce({}) do |baseh, an|
      baseh[an[:prefix]] ||= {}
      baseh[an[:prefix]][:class_parts] ||= []
      baseh[an[:prefix]][:class_parts] << an[:class_parts]
      baseh
    end
  end

  def parts
    @parts ||= analytes.reduce([]) do |parts, a|
      parts += a[:class_parts]  
    end.sort.uniq - analyte_tree.keys
  end

  def part_stems
    @part_stems ||= parts.
      map{|p| Lingua.stemmer p }.
      sort.
      reject{|stem| stem.size <= 2 }
  end

  def part_counts
    @ns_parts_counts ||= analytes.reduce({}) do |ag,a|
      ag[a[:prefix]] ||= []
      ag[a[:prefix]] << a[:class_parts].size
      ag 
    end
  end

  def parts_empty
    Hash[ parts.zip(Array.new(parts.size, [])) ]
  end

  def parts_positions 
    @parts_positions ||= analytes.reduce( parts_empty ) do |pos, a|
      a[:class_parts].each_with_index do |part, idx|
        pos[part] << idx
      end
      pos
    end
  end

# parts_positions['Component'].reduce(:+)/parts_positions['Component'].size.to_f
# parts_positions['Component'].group_by(&:itself).values.max_by(&:size).first

  private

  def klass_load(filename)
    @base = File.readlines(filename).
      map(&:strip).
      map{|c| c.sub('.h','').gsub(/[_-]/,'') }
  end

end


