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
        print "[#{(index + 1).to_s.rjust(total_count.to_s.length) }/#{total_count}] Exporting [#{transaction.created.to_s(:short)}] #{transaction.id}... "

        if transaction.amount.to_i == 0
          puts 'skipped: amount is 0'.light_blue
          next
        end

        if transaction.decline_reason.present?
          puts 'skipped: declined transaction'.light_blue
          next
        end

        if transaction.settled.to_s.empty? && settled_only
          puts 'skipped: transaction is not settled'.light_blue
          next
        end

        merchant = transaction.merchant
        suggested_tags = merchant.try(:raw_data).try(:[], 'metadata').try(:[], 'suggested_tags')

        memo = merchant.try(:emoji) || ''
        memo << " #{transaction.settled.to_s.empty? ? nil : '👍'}"
        memo << " #{suggested_tags}" if suggested_tags.present?
        memo.strip!

        qif << Qif::Transaction.new(
          date: transaction.created,
          amount: transaction.amount,
          memo: memo,
          payee: merchant.try(:name) || (transaction.is_load ? 'Topup' : 'Unkown')
        )

        puts 'exported'.green
      end
    end

    puts ''
    puts "Exported to: #{file.path}"
  end
end
