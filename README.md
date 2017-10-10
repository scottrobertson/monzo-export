# Monzo Export

Export Monzo Transactions to QIF and CSV files.

### Install

```
git clone git@github.com:scottrobertson/monzo-export.git
bundle
```

### Quick Start

```
MONZO=token from https://developers.monzo.com/
ruby monzo-export.rb csv --access_token=$MONZO --since=2016-10-10 --folder=/path/to/folder
ruby monzo-export.rb qif --access_token=$MONZO --since=2016-10-10 --folder=/path/to/folder
```

#### Quick Start Current Account

```
MONZO=token from https://developers.monzo.com/
ruby monzo-export.rb qif --access_token=$MONZO --since=2016-10-10 --folder=/path/to/folder --current_account
```

### OAuth Configuration

This allows you to use a token from a client you set up on `https://developers.monzo.com/` and then omit the `--access_token` argument.

Create a new client (either confidential or non-confidential) with a redirect url of `http://localhost/monzo-export` and then make a note of the `clientID` and `clientSecret`.

To configure Monzo To QIF to use OAuth, first run
```
ruby monzo-export.rb auth --clientid {clientID} --clientsecret {clientSecret}
```

This will prompt you to browse to the Monzo auth url in your browser to obtain your authorization code. Completing this workflow will result in Monzo sending you an email with a login link. You need to copy this link and use it in the next command.
```
ruby monzo-export.rb authurl --url {link-from-email}
```

This completes the setup, retrieves and stores the access token.

#### Differences between Confidential and Non-confidential clients

- A confidential client will also give you a refresh token which is automatically used when your access token expires without any further input.
- A non-confidential client will prompt the user to re-authenticate whenever the access token expires.

The tokens are stored locally in `config.yml` so anyone with access to this folder also has access to your access/refresh tokens.
