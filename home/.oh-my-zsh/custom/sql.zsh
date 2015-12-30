function to_sql_list() {
    awk '{print "\x27"$0"\x27," }'
}

