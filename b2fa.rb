require 'csv'

unless ARGV.length == 2
  puts "Usage: ruby b2fa.rb sample.csv sample-converted.csv"
  exit
end

# Helper to massage the currency columns
# The amount cannot contain commas, nor should it contain quote marks
def fix_currency(amount)
  return amount.gsub(',', '').gsub('"', '')
end

# Get the filenames
input_filename  = ARGV[0]
output_filename = ARGV[1]

# The list of transactions we've parsed
transactions = []

header_found  = false
start_balance = nil
end_balance   = nil

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

    # Get the debit/credit amounts
    debit   = fix_currency row[4]
    credit  = fix_currency row[5]

    # There should be a single 'amount' column that contains both money paid out and money paid in
    amount = 0
    if debit == "0.00"
      amount = credit
    else
      amount = "-" + debit
    end

    # The list is reversed with the latest at the top so the
    # end balance is first and the start balance is last
    unless end_balance
      end_balance = fix_currency(row[6]).to_f
    end
    start_balance = fix_currency(row[6]).to_f

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

# Perform some final calculations to ensure that the data is correct
index = 0
balance = start_balance
transactions.reverse.each do |transaction|
  amount = transaction[1].to_f
  #puts "Balance: #{balance.round(2).to_s}"
  
  unless index == 0
    balance += amount
  end
  
  #puts "\t\tAmount: #{amount.to_s}"
  #puts "\t\tBalance: #{balance.round(2).to_s}"
  index += 1
end

if balance.round(2) != end_balance
  puts "*** WARNING — There may be a problem!"
  puts "Start balance: #{start_balance.to_s}"
  puts "End balance: #{end_balance.to_s}"
  puts "Calculated end balance: #{balance.round(2).to_s}"
  puts "There's a discrepancy of $#{(balance-end_balance).abs.round(2).to_s}"
end

File.open(output_filename, "w") { |f| 
  f.write(transactions.inject([]) { |csv, row|  
    csv << CSV.generate_line(row) 
  }.join(""))
}

puts "Done!"