require 'csv'
require 'money'

I18n.enforce_available_locales = false
Money.locale_backend = :currency
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

class CsvCreator
  def initialize(transactions)
    @transactions = transactions
  end

  def create(path = nil, settled_only: false, account_number: nil)
    path ||= 'exports'
    path.chomp!('/')

    file = File.open("#{path}/monzo#{account_number ? "_#{account_number}" : nil}.csv", "w")

    CSV.open(file, "wb") do |csv|

      csv << [:date, :description, :memo, :amount]

      total_count = @transactions.size
      @transactions.each_with_index do |transaction, index|

        transaction.created = DateTime.parse(transaction.created)

        amount = (transaction.amount.to_f / 100).abs.to_s.ljust(6, ' ')
        amount_with_color = transaction.amount > 0 ? amount.green : amount.red

        print "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] #{transaction.created.to_date.to_s} - #{transaction.id} - #{amount_with_color}  "

        if transaction.amount.to_f == 0.0
          puts "skipped: amount is #{transaction.amount}".light_blue
          next
        end

        if transaction.decline_reason
          puts 'skipped: declined transaction'.red
          next
        end

        if transaction.settled.empty? && transaction.amount < 0 && settled_only
          puts 'skipped: transaction is not settled'.light_blue
          next
        end

        if transaction.merchant
          suggested_tags = transaction.merchant.metadata.suggested_tags if transaction.merchant.metadata.suggested_tags
          memo = transaction.merchant.emoji
        else
          suggested_tags = nil
          memo = ''
        end

        foreign_transaction = transaction.local_currency != transaction.currency
        if foreign_transaction
          money = ::Money.new(transaction.local_amount.abs, transaction.local_currency)
          memo.prepend("(#{money.format}) ")
        end

        merchant_name = transaction.merchant ? transaction.merchant.name : nil
        merchant_name ||= transaction.counterparty ? transaction.counterparty.name : nil

        csv << [
          transaction.created.strftime("%d/%m/%Y"),
          merchant_name,
          memo.strip,
          transaction.amount.to_f / 100,
        ]

        puts 'exported'.green
      end
    end

    puts ''
    puts "Exported to: #{file.path}"
  end
end
