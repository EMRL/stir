<?php

function approved()
{
		$denied_file = '{{PATHTOREPO}}/.denied';
		$approved_file = '{{PATHTOREPO}}/.approved';
		$status = isset($_GET['approval']) ? $_GET['approval'] : null;

		if ($status === 'yes') {
				$status = true;
				@unlink($denied_file);
				touch($approved_file);
		} elseif ($status === 'no') {
				$status = false;
				@unlink($approved_file);
				touch($denied_file);
		}

		// returns true for approved, false for denied, or null for neither
		return $status;
}
?>
<!doctype html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="x-apple-disable-message-reformatting">
	<title></title>
	<!--[if mso]>
		<style>
			* {font-family: Arimo, sans-serif !important;}
		</style>
	<![endif]-->
	
	<!--// Outlook webfont fallback //-->
	<!--[if !mso]><!-->
		<!--// insert web font reference if needed: <link href="https://fonts.googleapis.com/css?family=Arimo" rel="stylesheet"> //-->
	<!--<![endif]-->
	<style>
		html,
		body {margin: 0 auto !important; padding: 0 !important; height: 100% !important; width: 100% !important;}
		* {-ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%;}
		div[style*="margin: 16px 0"] {margin:0 !important;}
		table, td {mso-table-lspace: 0pt !important; mso-table-rspace: 0pt !important;}     
		table {border-spacing: 0 !important; border-collapse: collapse !important; table-layout: fixed !important; margin: 0 auto !important;}
		table table table {table-layout: auto;}        
		img {-ms-interpolation-mode:bicubic;}       
		.mobile-link--footer a, a[x-apple-data-detectors] {color:inherit !important; text-decoration: underline !important;}
		/* Don't underline text in Windows 10 */
		.button-link {text-decoration: none !important;}
		.button-td, .button-a {transition: all 100ms ease-in;}
		.button-td:hover, .button-a:hover {background: #222222 !important; border-color: #222222 !important;}
		@import url('https://fonts.googleapis.com/css?family=Arimo');
		@media screen and (max-width: 600px) {
			.email-container {width: 100% !important; margin: auto !important;}
			.fluid {max-width: 100% !important; height: auto !important; margin-left: auto !important; margin-right: auto !important;}
			.stack-column, .stack-column-center {display: block !important; width: 100% !important; max-width: 100% !important; direction: ltr !important;}
			.stack-column-center {text-align: center !important;}
			.center-on-narrow {text-align: center !important; display: block !important; margin-left: auto !important; margin-right: auto !important; float: none !important;}
			table.center-on-narrow {display: inline-block !important;}
		}
	</style>
	<link href="https://fonts.googleapis.com/css?family=Arimo" rel="stylesheet">
</head>

<body bgcolor="#f0f0f0" width="100%" style="margin: 0;">
	<table border="0" width="100%" height="100%" cellpadding="0" cellspacing="0" bgcolor="#f1f1f1" valign="top">
		<tr>
			<td valign="top" bgcolor="#f1f1f1">
				<div style="max-width: {{VIEWPORT}}px; margin: auto;"> 
				<!--// More Microsoft stuff =[ //--> 
				<!--[if mso]>
					<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="{{VIEWPORT}}" align="center">
						<tr>
							<td>
				<![endif]-->  
					<table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" width="100%" style="max-width: {{VIEWPORT}}px;">
							<tr>
							<td bgcolor="#ffffff" style="padding: 40px; text-align: left; font-family: Arimo, sans-serif; font-size: 15px; mso-height-rule: exactly; line-height: 20px; color: #555555;"><h1 style="display: block; font-family: Arimo, sans-serif; font-size: 44px; font-style: normal; font-weight: bold; line-height: 100%;  text-align: left; color: #000000 !important; margin: 0 0 10px 0;">{{LOGTITLE}}</h1>
								<style>@media (max-width: 768px) {.hide {display:none; !important}}</style>
								<!--[CLIENTLOGO]--><img src="{{CLIENTLOGO}}" class="hide" style="width: 20%; min-width: 32px; max-width: 192px; float: right; -webkit-border-radius: 4px; -moz-border-radius: 4px; -ms-border-radius: 4px; -khtml-border-radius: 4px; border-radius: 4px; overflow: hidden; margin-left: 1.0em;" alt="{{PROJCLIENT}}" title="{{PROJCLIENT}}">
								<p style="font-family: Arimo, sans-serif; font-size: 18px; line-height: 26px; font-style: normal; font-weight: 400;"><strong>Date:</strong> {{NOW}}<br />
								<strong>Project:</strong> {{PROJNAME}} ({{PROJCLIENT}}) <br />
								<strong>Staging URL:</strong> <a style="color: #47ACDF; text-decoration:none; font-weight: bold;" href="{{DEVURL}}">{{DEVURL}}</a><br />
								<strong>Production URL:</strong> <a style="color: #47ACDF; text-decoration:none; font-weight: bold;" href="{{PRODURL}}">{{PRODURL}}</a>
								</p>

					<p><strong>Proposed commit from {{USER}}</strong><br />
						{{NOTES}}</p>
<?php
$approved = approved();

if (is_null($approved)) {
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
} elseif ($approved) {
		echo 'You have approved this commit and it will be deployed soon.';
} else {
		echo 'You have denied this commit and it will not be deployed.';
}
?>
				</td>
			</tr>
			<!--// ONE COLUMN: END //-->

			<!--// TEXT BLOCK: BEGIN //-->
			<tr>
				<td>
					<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
						<tr>
			  				<td style="background: #f0f0f0; padding-left: 40px; font-family: sans-serif; font-size: 15px; mso-height-rule: exactly; line-height: 20px; color: #555555;"><pre style="font: 100% courier,monospace; border: none; overflow: auto; overflow-x: scroll;  max-width: {{VIEWPORTPRE}}px; color: #000; background: #f0f0f0;"><code style="font-size: 80%;">
