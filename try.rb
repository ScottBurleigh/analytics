AUTH_TOKEN = "DQAAAO8AAACjYt_ZDMuNX_TRghTqzjGW6N-NhTru2PsgbMToGuhHNR3BkErZMYLc8241ji8Nqd5-bEnktF0EQtWDfWm5GjNwzExHSL7OrYlH10ZjQ2glbMz--UWGHZlR09xzHpXKNJplJo6MfV8qGKwz-1a3A2kA7U3KdK0BUFdqqgPOqwAm95u2wixFi7NAagxZcgoBDsy-N5mrdTQwTv6fCc757aBgpUzEdHsrqbZriLv7BQ6VACfYLb9BF9h4oVWsMvk6Z36aQm7tqNr8i4QecrNewBLm40RcxR6wOy5ueJ3Li4e4Iah1CJfBolbO0b9BZuxEuo8"

cmd1 = %[curl -H "Authorization: GoogleLogin auth=#{AUTH_TOKEN}" https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties]

first_day = '2010-06-17'
last_day = '2012-07-24'

account_id = "33811739"

visits_cmd= %[curl -H "Authorization: GoogleLogin auth=#{AUTH_TOKEN}" "https://www.googleapis.com/analytics/v3/data/ga/?ids=ga:#{account_id}&metrics=ga:visits&dimensions=ga:date&start-date=#{first_day}&end-date=#{last_day}"]



#system visits_cmd

