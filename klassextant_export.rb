module KlassextantExport
  require 'csv'
  require 'json'

  def export_class_parts( format=:csv )
    case format
    when :csv
      CSV.open('class_parts.csv', 'wb') do |csv|
        fb.analytes.each do |an|
          csv << [ [an[:prefix], *an[:class_parts], 'end'][0..5].join('-') ]
        end
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end

  def export_stem_counts( format=:csv )
    case format
    when :csv
      CSV.open("stem_counts.csv", 'wb') do |csv|
        csv << ['stem', 'raw_positions', 'clusters', 'total_use', 'avg_pos', 'median']
        @stem_counts.each do |k,v|
          csv << [k, v[:raw], v[:clusters], v[:total_use], v[:avg_pos], v[:median]] 
        end
      end
    case :json
      File.open("stem_counts.json", "w") do |f|
        f.write( JSON.generate(@stem_counts) )  
      end
    else
      raise ArgumentError, 'Unsupported export type', format
    end
  end

end

