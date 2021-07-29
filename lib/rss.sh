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
	"${curl_cmd}" --silent "${NEWS_URL}" > /tmp/${APP}.xml; error_check
	# Strip CDATA stuff
	"${xmlstarlet_cmd}" fo --omit-decl --nocdata /tmp/${APP}.xml > ${stat_file}
	# Clean up mess
	rm /tmp/${APP}.xml
}

function next_xml() {
	local IFS='>'
  read -d '<' TAG VALUE
}

function process_xml() {
	cat ${stat_file} | while next_xml ; do
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
				# Convert pubDate format for <time datetime="">
				datetime=$( date --date "$VALUE" --iso-8601=minutes )
				pubDate=$( date --date "$VALUE" '+%A, %B %d' )
				;;
			'description')
				# Convert '&lt;' and '&gt;' to '<' and '>'
				description=$( echo "$VALUE" | sed -e 's/&lt;/</g' -e 's/&gt;/>/g' )
				;;
			'/item')
			cat<<EOF
<td valign="top" style="padding: 10px 20px; text-align: left; font-family: Roboto, sans-serif; font-size: 13px; mso-height-rule: exactly; color: {{DEFAULT_COLOR}};"><article><strong><a style="font-size: 15px; color: {{PRIMARY}}; text-decoration: none; font-weight: bold;" href="$link">$title</a></strong><br /><time datetime="$datetime">$pubDate</time>$description</article></td>
EOF
;;
	  esac
	done
}

function create_rss_payload() {
	if [[ -z "${NEWS_URL}" ]] || [[ -z "${xmlstarlet_cmd}" ]]; then
		NEWS_URL=""
		return
	else
		get_rss
		process_xml > ${trash_file}

		# Clean up output
		sed -i 's/\xc2\x91\|\xc2\x92\|\xc2\xa0\|\xe2\x80\x8e//g' "${trash_file}"

		# Centos doesn't have the inplace option 
		# awk -i inplace '{gsub(/’/, "'"'"'");print}' "${post_file}"
		awk '{gsub(/’/, "'"'"'");print}' "${trash_file}" > "${post_file}"


		sed -r -i -e '/<p>The post /d' \
			-e "s/&amp;#160;/\ /g" \
			-e "s/&amp;#8230;/\.../g" \
			"${post_file}"

		# Escape quotes
		sed -i "s/'/\'/g" "${post_file}"

		# Remove newlines
		sed -i ':a;N;$!ba;s/\n//g' "${post_file}"
		sed -i -e :a -e '$!N;s/\n[[:blank:]]\{1,\}/ /;ta' -e 'P;D' "${post_file}"

		# empty_line; cat "${post_file}"
		RSS_NEWS="$(<${post_file})"
	fi
}
