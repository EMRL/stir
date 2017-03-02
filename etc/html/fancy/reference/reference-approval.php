<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="x-apple-disable-message-reformatting">
<title></title>

<!--// Try to reset CSS //-->
<style>
html, body {
	margin: 0 auto !important;
	padding: 0 !important;
	height: 100% !important;
	width: 100% !important;
}
* {
	-ms-text-size-adjust: 100%;
	-webkit-text-size-adjust: 100%;
}
div[style*="margin: 16px 0"] {
	margin: 0 !important;
}
table, td {
	mso-table-lspace: 0pt !important;
	mso-table-rspace: 0pt !important;
}
table {
	border-spacing: 0 !important;
	border-collapse: collapse !important;
	table-layout: fixed !important;
	margin: 0 auto !important;
}
table table table {
	table-layout: auto;
}
img {
	-ms-interpolation-mode: bicubic;
}
/* Dammit iOS quit messing with links */
.mobile-link--footer a, a[x-apple-data-detectors] {
	color: inherit !important;
	text-decoration: underline !important;
}
/* Don't underline text in Windows 10 */
.button-link {
	text-decoration: none !important;
}
</style>
<style>
/* Hover styles for buttons, it could happen */


.button-td, .button-a {
	transition: all 100ms ease-in;
	padding: 0px 8px 0px 8px;
}
.button-td:hover, .button-a:hover {
	background: #1A242F !important;
	border-color: #1A242F !important;
}
 @media screen and (max-width: 600px) {
.email-container {
	width: 100% !important;
	margin: auto !important;
}
.fluid {
	max-width: 100% !important;
	height: auto !important;
	margin-left: auto !important;
	margin-right: auto !important;
}
.stack-column, .stack-column-center {
	display: block !important;
	width: 100% !important;
	max-width: 100% !important;
	direction: ltr !important;
}
.stack-column-center {
	text-align: center !important;
}
.center-on-narrow {
	text-align: center !important;
	display: block !important;
	margin-left: auto !important;
	margin-right: auto !important;
	float: none !important;
}
table.center-on-narrow {
	display: inline-block !important;
}
}
</style>
</head>

<body bgcolor="#f0f0f0" width="100%" style="margin: 0;">
<center style="width: 100%; background: #f0f0f0;">
  <div style="max-width: 680px; margin: auto;"> 
    <!--// More Microsoft stuff =[ //--> 
    <!--[if mso]>
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="680" align="center">
            <tr>
            <td>
            <![endif]--> 
    
    <!--// BODY: BEGIN //-->
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="100%" style="max-width: 680px;">
      
      <!--// ONE COLUMN: BEGIN //-->
      <tr>
        <td bgcolor="#ffffff" style="padding: 40px; text-align: left; font-family: sans-serif; font-size: 15px; mso-height-rule: exactly; line-height: 20px; color: #555555;"><h1 style="display: block; font-family: Arial, sans-serif; font-size: 44px; font-style: normal; font-weight: bold; line-height: 100%; letter-spacing: -2px; text-align: left; color: #000000 !important; margin: 0 0 10px 0;">Deployment Approval</h1>
          <img src="http://emrl.com/app/themes/emrl/assets/img/apple-touch-icon-144x144.png" style="width: 100px; float: right; -webkit-border-radius: 4px; -moz-border-radius: 4px; -ms-border-radius: 4px; -khtml-border-radius: 4px; border-radius: 4px;
    overflow: hidden;" alt="EMRL" title="EMRL">
          <p style="font-family: Arial, sans-serif; font-size: 18px; line-height: 26px; font-style: normal; font-weight: 400;"><strong>Date:</strong> 03/01/2017 (07:58:19 PM)<br />
            <strong>Project:</strong> EMRL Website (EMRL) <br />
            <strong>Staging URL:</strong> <a style="color: #47ACDF; text-decoration:none; font-weight: bold;" href="http://emrl.mx/">http://emrl.mx/</a><br />
            <strong>Production URL:</strong> <a style="color: #47ACDF; text-decoration:none; font-weight: bold;" href="http://emrl.com/">http://emrl.com/</a> </p>
          <p><strong>Proposed Commit</strong><br />
            Updated 2 of 2 plugins (advanced-custom-fields-pro 5.5.9, akismet 3.3, wordfence 6.3.2)</p>
          <?php
session_start();
$run_func = '';

if ($_GET['approval'] == 'yes') { 
    approval(); 
} else { 
    echo '<!--// BUTTONS: BEGIN //-->
          <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="left" style="margin: auto">
            <tr>
              <td style="border-radius: 3px; background: #CC2233; text-align: center;" class="button-td"><a href="?approval=no" style="background: #CC2233; border: 15px solid #CC2233; font-family: sans-serif; font-size: 13px; line-height: 1.1; text-align: center; text-decoration: none; display: block; border-radius: 3px; font-weight: bold;" class="button-a"> <span style="color: #ffffff;">Deny</span> </a></td>
          	  <td style="width: 10px;"></td>
              <td style="border-radius: 3px; background: #47ACDF; text-align: center;" class="button-td"><a href="?approval=yes" style="background: #47ACDF; border: 15px solid #47ACDF; font-family: sans-serif; font-size: 13px; line-height: 1.1; text-align: center; text-decoration: none; display: block; border-radius: 3px; font-weight: bold;" class="button-a"> <span style="color: #ffffff;">Approve</span> </a></td>
            </tr>
          </table>
          <!--// BUTTONS: END //-->
	'; 
} 

function approval()  
{ 
// Output file
$file = 'approved.sh';
 
// Does the file already exist?
if(!is_file($file)){
    // Compile the script that cron will fire
    $contents = '#!/bin/bash\n
export TERM=${TERM:-dumb}\n
source ${HOME}/.bash_profile 2>&1\n
source ${HOME}/.keychain/${HOSTNAME}-sh 2>&1\n
deploy --approve ${APP}';
    // Save the file
    file_put_contents($file, $contents);
}
}
?></td>
      </tr>
      <!--// ONE COLUMN: END //--> 
      
      <!--// TEXT BLOCK: BEGIN //-->
      <tr>
        <td><table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
            <tr>
              <td style="padding-left: 40px; font-family: sans-serif; font-size: 15px; mso-height-rule: exactly; line-height: 20px; color: #555555;"><pre style="font: 100% courier,monospace; border: none; width: 600px; overflow: auto; overflow-x: scroll;  width: 600px; color: #000;"><code style="font-size: 80%;">

Deployment logfile for EMRL - 10/16/2016 (07:00:00 PM)

TRACE: Loading deployment functions
TRACE: Loading console styles
TRACE: Loading error checking
TRACE: Loading git libraries
TRACE: Locking process
TRACE: Loading log handling
TRACE: Loading package management
TRACE: Loading permissions fixes
TRACE: Loading post integration
TRACE: Loading exit states
TRACE: Loading server checks
TRACE: Loading Slack integration
TRACE: Loading smart commit functions
TRACE: Loading SSH checks
TRACE: Loading user feedback
TRACE: Loading utilities
TRACE: Loading Wordpress functions
TRACE: Loading input functions
TRACE: Version 3.4.5
TRACE: Running from /etc/deploy
TRACE: Loader found at /etc/deploy/lib/loader.sh
TRACE: Loading system configuration file from /etc/deploy/deploy.conf
TRACE: Loading user configuration from ~/.deployrc
TRACE: Loading project configuration from /var/www/html/emrl/config/deploy.sh
TRACE: Smart commits are enabled
TRACE: Slack integration enabled, using https://hooks.slack.com/services/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
TRACE: Email integration enabled, using task-3969@projects.emrl.com
TRACE: Remote log posting enabled
TRACE: Log file is /tmp/emrl.log-23085.log
TRACE: Plugin updates log is /tmp/emrl.wp-17372.log
TRACE: Core upgrade log is /tmp/emrl.core-16977.log
TRACE: Post file is /tmp/emrl.wtf-24255.log
TRACE: Trash file is /tmp/emrl.trsh-31051.log
TRACE: Stat file is /tmp/emrl.stat-14700.log
TRACE: URL file is /tmp/emrl.url-27286.log
TRACE: Development workpath is /var/www/html
TRACE: Automerge is enabled
TRACE: Current project is emrl
TRACE: Current user is fdiebel@varese.emrl.mx
TRACE: Git lock at /var/www/html/emrl/.git/index.lock
TRACE: Creating lockfile
TRACE: Loading project.

Checking servers...
 https://bitbucket.org/emrl/emrl/ [33mOK\e[0m
 http://emrl.mx/ (development) [33mOK\e[0m
 http://emrl.com/ (production) [33mOK\e[0m

Checking out master branch...
TRACE: Checking Index
TRACE: Looks good.
Already on 'master'
Your branch is up-to-date with 'origin/master'.

Preparing repository...
TRACE: Status looks good
TRACE: wp-cli found, checking for Wordpress.
TRACE: Wordpress found.
TRACE: Wordfence found.

WARNING: Wordfence firewall detected, and may cause issues with deployment.
ERROR: Deployment can not continue while Wordfence firewall is enabled.
TRACE: Posting logs to remote server
</code></pre></td>
            </tr>
          </table></td>
      </tr>
      <!--// TEXT BLOCK: END //-->
      
    </table>
    <!--// BODY: END //--> 
    
    <!--// FOOTER (Style 2): BEGIN //-->
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="680" style="margin: auto;" class="email-container">
      <tr>
        <td style="padding: 40px 10px;width: 100%;font-size: 12px; font-family: sans-serif; mso-height-rule: exactly; line-height:18px; text-align: center; color: #888888;"><a href="http://emrl.com"><img class="aligncenter" src="http://emrl.co/assets/img/emrlsq.jpg" alt="EMRL" /></a>
          <p style="text-align: center; font-family: Arial, sans-serif;"><a style="color: #000000; text-decoration: none;" href="http://emrl.com">EMRL</a> &bull; 1020 Tenth Street &bull; Sacramento, CA 95814 &bull; (916) 446-2440<br />
            <a style="color: #47ACDF; text-decoration:none; text-transform: uppercase; font-weight: bold;" href="#">We <span style="color: #CC2233">&hearts;</span> your code</a></p></td>
      </tr>
    </table>
    <!--// FOOTER (Style 2): END //--> 
    
  </div>
</center>
</body>
</html>
