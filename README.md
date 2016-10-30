# Monzo to QIF

Export Monzo Transactions to a QIF file.

### Install

```
git clone git@github.com:scottrobertson/monzo-to-qif.git
bundle
```

### Run

```
MONZO=token from https://developers.monzo.com/
ruby monzo-to-qif.rb generate --access_token=$MONZO --since=2016-10-10 --folder=/path/to/folder
```
