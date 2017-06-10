require 'qif'

class QifCreator
  def initialize(transactions)
    @transactions = transactions
  end

  def create(path = nil, settled_only: false)
    path ||= 'exports'
    path.chomp!('/')

    file = File.open("#{path}/#{rand(999)}_#{Time.now.to_i}.qif", "w")
    Qif::Writer.open(file.path, type = 'Bank', format = 'dd/mm/yyyy') do |qif|
      total_count = @transactions.size
      @transactions.each_with_index do |transaction, index|

        transaction.created = DateTime.parse(transaction.created)

        print "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] Exporting [#{transaction.created.to_s}] #{transaction.id}... "

        if transaction.amount.to_i == 0
          puts 'skipped: amount is 0'.light_blue
          next
        end

        if transaction.decline_reason
          puts 'skipped: declined transaction'.red
          next
        end

        if transaction.settled.empty? && settled_only
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

        memo << " #{transaction.settled.to_s.empty? ? nil : '👍'}"
        memo << " #{suggested_tags}" if suggested_tags
        memo.strip!

        qif << Qif::Transaction.new(
          date: transaction.created,
          amount: transaction.amount,
          memo: memo,
          payee: (transaction.merchant ? transaction.merchant.name : nil) || (transaction.is_load ? 'Topup' : 'Unkown')
        )

        puts 'exported'.green
      end
    end

    puts ''
    puts "Exported to: #{file.path}"
  end
end
