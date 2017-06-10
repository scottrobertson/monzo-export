#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'colorize'
require_relative 'lib/transaction_fetcher'
require_relative 'lib/qif_creator'

program :name, 'Monzo to QIF'
program :version, '0.0.1'
program :description, 'Create QIF files from your Monzo account'

command :generate do |c|
  c.syntax = 'Monzo to QIF generate [options]'
  c.summary = 'Generate the QIF file'
  c.description = ''
  c.option '--access_token TOKEN', String, 'Your access token from: https://developers.monzo.com/'
  c.option '--since DATE', String, 'The date (YYYY-MM-DD) to start exporting transactions from. Defaults to two weeks ago.'
  c.option '--folder PATH', String, 'The folder to export to. Defaults to ./exports'
  c.option '--settled_only', String, 'Only export settled transactions'
  c.action do |args, options|
    since = options.since ? Date.parse(options.since).to_time : nil
    if options.access_token
      transactions = TransactionFetcher.new(options.access_token, options.account_id).fetch(since: since)
      qif = QifCreator.new(transactions).create(options.folder, settled_only: options.settled_only)
    else
      say 'Please supply an access_token'
    end
  end
end
