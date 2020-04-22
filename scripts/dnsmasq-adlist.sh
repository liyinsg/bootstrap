#!/bin/bash
set -e
# starts with || and ends with ^, may contains *
ADGUARD=https://filters.adtidy.org/extension/chromium/filters/15.txt
# dnsmasq rules, starts with address=/, and ends with /
ANTIAD=https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/adblock-for-dnsmasq.conf

# remove wildcard
curl -s $ADGUARD | grep "^||" | sed 's/^||//g' | sed 's/\^//g' | tr -d '\r' | sort -u > /tmp/adguard.txt
curl -s $ANTIAD | grep "^address=" | sed 's/address\=\///g'  | sed 's/\///g' | tr -d '\r' |sort -u > /tmp/antiad.txt
comm -13 /tmp/adguard.txt /tmp/antiad.txt > /tmp/combined.txt
WILDNAME=$(cat /tmp/adguard.txt | grep "\*" | grep -o "[a-zA-Z0-9-]\+\\.com" | cut -d '.' -f 1 | sort -u)
for n in $WILDNAME
do
	sed -i "/$n\./d" /tmp/combined.txt
done
sed -i "/uukanshu/d" /tmp/combined.txt
rm /tmp/adguard.txt /tmp/antiad.txt

sed -i 's/^/address\=\//g' /tmp/combined.txt
sed -i 's/$/\//g' /tmp/combined.txt
mv -f /tmp/combined.txt /etc/dnsmasq.d/dnsmasq.adlist.conf

# restart service
/etc/init.d/dnsmasq force-reload
/opt/vyatta/bin/sudo-users/vyatta-op-dns-forwarding.pl --clear-cache
