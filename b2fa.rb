require 'csv'

unless ARGV.length == 2
  puts "Usage: ruby b2fa.rb sample.csv sample-converted.csv"
  exit
end

# Get the filenames
input_filename  = ARGV[0]
output_filename = ARGV[1]

# The list of transactions we've parsed
transactions = []

header_found = false

CSV.foreach(input_filename, quote_char: '"', col_sep: ',', row_sep: :auto, headers: true) do |row|
  
  # Look for the header row. We know the transactions start on the following line
  if row[0] == 'Transaction Date'
    header_found = true
    next
  end

  if header_found
    # The date format must be dd/mm/yyyy
    date = row[0].gsub('-', '/')

    # The description can't include any quote marks (")
    # Also remove extra whitespace
    description = row[3].gsub('"', '').strip

    # The amount cannot contain commas, nor should it contain quote marks
    debit   = row[4].gsub(',', '').gsub('"', '')
    credit  = row[5].gsub(',', '').gsub('"', '')

    # There should be a single 'amount' column that contains both money paid out and money paid in
    amount = 0
    if debit == "0.00"
      amount = credit
    else
      amount = "-" + debit
    end

    # puts "Row: #{row}"
    # puts "Date: #{date}"
    # puts "Desc: \"#{description}\""
    # puts "Debit: #{debit}"
    # puts "Credit: #{credit}"
    # puts "Amount: #{amount}"
    
    # Add the transaction
    transactions.push([date, amount, description])
  end
end

File.open(output_filename, "w") { |f| 
  f.write(transactions.inject([]) { |csv, row|  
    csv << CSV.generate_line(row) 
  }.join(""))
}

puts "Done!"