#!/usr/bin/env bash
export SELFDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CRAWLDIR=${SELFDIR}/"tmp"
export ALLOWED=${SELFDIR}/"allowed.txt"
export ORIGIN="http://www.abyznewslinks.com/"
export DOMAINS=${CRAWLDIR}"/domains.txt"
export OUT=${SELFDIR}/nonews.lsrules
export OUTTMP=${OUT}.tmp

set -eo pipefail

echo "building list"

rm -rf ${CRAWLDIR} && mkdir -p ${CRAWLDIR}
cd ${CRAWLDIR} && wget -r -l 2 $ORIGIN
rm -rf ${DOMAINS}
find ${CRAWLDIR} -type f |\
    xargs grep -h -o '<a href=".*">' |\
    sed -n 's/.*href="\([^"]*\).*/\1/p' |\
    grep ^http |\
    awk -F \/ '{l=split($3,a,"."); print (a[l-1]=="com"?a[l-2] OFS:X) a[l-1] OFS a[l]}' OFS="." |\
    grep -v "&#" |\
    grep -v "^\." |\
    grep -v -f ${ALLOWED} |\
    sort -u >> ${DOMAINS}

rm -rf ${OUTTMP}
cat << EOF >> ${OUTTMP}
{
	"description" : " No more news the little snitch way ",
	"name" : "nonews.lsrules",
	"rules" :  [
EOF

for DOMAIN in $(cat ${DOMAINS})
do
echo "processing ${DOMAIN}"
cat << EOF >> ${OUTTMP}
        {
            "action" : "deny",
            "notes" : "",
            "owner" : "me",
            "process" : "any",
            "remote-domains": "${DOMAIN}"
        },
EOF
done

cat << EOF >> ${OUTTMP}
        {
            "action" : "deny",
            "notes" : "",
            "owner" : "me",
            "process" : "any",
            "remote-domains": "foxnews.com"
        }
EOF

cat << EOF >> ${OUTTMP}
]}
EOF

cat ${OUTTMP} | jq . > ${OUT}
rm -rf ${OUTTMP}

