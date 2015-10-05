module KlassextantExport
  require 'csv'
  require 'json'

  def export_class_parts( format='csv' )
    case format
    when 'csv'
      CSV.open('class_parts.csv', 'wb') do |csv|
        fb.analytes.each do |an|
          csv << [ [an[:prefix], *an[:class_parts], 'end'][0..5].join('-') ]
        end
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end

  def export_stem_counts( format='csv' )
    case format
    when 'csv'
      CSV.open("stem_counts.csv", 'wb') do |csv|
        csv << ['stem', 'raw_positions', 'clusters', 'total_use', 'avg_pos', 'median']
        @stem_counts.each do |k,v|
          csv << [k, v[:raw], v[:clusters], v[:total_use], v[:avg_pos], v[:median]] 
        end
      end
    when 'json'
      File.open("stem_counts.json", "w") do |f|
        f.write( JSON.generate(@stem_counts) )  
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end

  def export_stem_trees( format='json', kind=:rich )
    flare_tree = nest_by_alpha(
      (kind == :rich) ? @stem_tree.reject{|k,v| v.size == 1 } : @stem_tree
    )
    file_name = ['stem_tree',kind.to_s].join('_')

    case format
    when 'json'
      File.open("#{file_name}.ison", "w") do |f|
        f.write( JSON.generate(flare_tree) )  
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end

  def export_stem_flats( format='json' )
    @tree = {'name' => 'flare','children' => []}

    st.
      select     	 {|k,v| v.size == 1 }.
      group_by   	 {|k,v| k[0] }.
      reduce({}) 	 {|a,k| a[k.first] = k.last.map(&:first); a }.
      reduce(@tree) {|tree,group|
        tree['children'] << {
          'name'     => group.first,
          'children' => group.last.map{|stem|
            {'name'=>stem, 'value'=>1}
          }
        }
      }

    case format
    when 'json'
      File.open("stem_flats.ison", "w") do |f|
        f.write( JSON.generate(@tree) )  
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end


  # only nests 3 levels deep, as per the data
  # group_by param is the 'root' level
  def nest_by_alpha( tree )
    flare_tree = {'name':'flare','children':[]}
    tree.
      group_by{|k,v| k[0] }.
      each do |k,v| flare_tree['children'] << {
        'name'     => k,
        'children' => v.map {|k2,v2| {
          'name'     => k2,
          'children' => v2.map {|k3,v3| {
            'name'     => k3,
            'value'    => '1'}
				}
        }
			}
      }
		end
  end

end
