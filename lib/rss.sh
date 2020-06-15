#!/usr/bin/env bash
#
# rss.sh
#
###############################################################################
# Grab an RSS feed, thanks to https://www.linuxjournal.com/content/parsing-rss-news-feed-bash-script
###############################################################################

var=(title link pubDate description RSS_NEWS)
init_loop

function get_rss() {
	# Pull RSS feed
	# wget --quiet -O /tmp/${APP}.xml ${NEWS_URL}
	"${curl_cmd}" --silent "${NEWS_URL}" > /tmp/${APP}.xml
	# Strip CDATA stuff
	xmlstarlet fo --omit-decl --nocdata /tmp/${APP}.xml > ${statFile}
	# Clean up mess
	rm /tmp/${APP}.xml
}

function next_xml() {
	local IFS='>'
  read -d '<' TAG VALUE
}

function process_xml() {
	cat ${statFile} | while next_xml ; do
		case $TAG in
			'item')
				title=''
				link=''
				pubDate=''
				description=''
				;;
			'title')
				title="$VALUE"
				;;
			'link')
				link="$VALUE"
				;;
			'pubDate')
				# convert pubDate format for <time datetime="">
				datetime=$( date --date "$VALUE" --iso-8601=minutes )
				pubDate=$( date --date "$VALUE" '+%A, %B %d' )
				;;
			'description')
				# convert '&lt;' and '&gt;' to '<' and '>'
				description=$( echo "$VALUE" | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' )
				;;
			'/item')
			cat<<EOF
<td valign="top" style="padding: 10px 20px; text-align: left; font-family: Roboto, sans-serif; font-size: 13px; mso-height-rule: exactly; color: {{DEFAULTC}};"><article><strong><a style="font-size: 15px; color: {{PRIMARY}}; text-decoration: none; font-weight: bold;" href="$link">$title</a></strong><br /><time datetime="$datetime">$pubDate</time>$description</article></td>
EOF
;;
	  esac
	done
}

function create_rss_payload() {
	# Testing only
	# NEWS_URL=https://emrl.com/feed/
	# APP=test
	# statFile=test.rss
	# postFile=test.html

	if [[ -z "${NEWS_URL}" ]]; then
		return
	else
		get_rss
		process_xml > ${postFile}

		# Clean up output
		sed -i 's/\xc2\x91\|\xc2\x92\|\xc2\xa0\|\xe2\x80\x8e//g' "${postFile}"
		# iconv -c -f utf-8 -t ascii "${postFile}"

		sed -r -i -e '/<p>The post /d' \
			-e "s/&amp;#160;/\ /g" \
			-e "s/&amp;#8230;/\.../g" \
			"${postFile}"

		# Remove newlines
		sed -i ':a;N;$!ba;s/\n//g' "${postFile}"

		RSS_NEWS="$(<${postFile})"
	fi
}
