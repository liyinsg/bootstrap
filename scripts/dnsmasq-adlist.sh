#!/bin/bash
set -e
# starts with || and ends with ^, may contains *
ADGUARD=https://filters.adtidy.org/extension/chromium/filters/15.txt
# dnsmasq rules, starts with address=/, and ends with /
ANTIAD=https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/adblock-for-dnsmasq.conf

curl -s $ADGUARD | grep "^||" | sed 's/^||//g' | sed 's/\^//g' | tr -d '\r' | sort -u > /tmp/adguard.txt
curl -s $ANTIAD | grep "^address=" | sed 's/address\=\///g'  | sed 's/\///g' | tr -d '\r' |sort -u > /tmp/antiad.txt
comm -13 /tmp/adguard.txt /tmp/antiad.txt > /tmp/combined.txt
rm /tmp/adguard.txt /tmp/antiad.txt
sed -i 's/^/address\=\//g' /tmp/combined.txt
sed -i 's/$/\//g' /tmp/combined.txt
mv -f /tmp/combined.txt /etc/dnsmasq.d/dnsmasq.adlist.conf
