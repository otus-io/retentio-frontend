awk '{print $3}' /var/log/squid/access.log | sort | uniq -c | sort -nr
