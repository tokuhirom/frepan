<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title><? block title => 'FrePAN' ?></title>
    <meta http-equiv="Content-Style-Type" content="text/css" />  
    <meta http-equiv="Content-Script-Type" content="text/javascript" />  
    <link rel="alternate" type="application/rss+xml" title="RSS" href="http://feeds.feedburner.com/YetAnotherCpanRecentChanges" />
    <link href="<?= uri_for('/static/css/screen.css') ?>" rel="stylesheet" type="text/css" media="screen" />
    <link href="<?= uri_for('/static/css/main.css') ?>" rel="stylesheet" type="text/css" media="screen" />
</head>
<body id="<? block body_id => "Default" ?>">
    <div id="Container">
        <div id="Header">
            <a href="<?= uri_for('/') ?>"><img src="<?= uri_for('/static/img/frepan-logo.png') ?>" alt="FrePAN" /></a>
        </div>
        <div id="Content">
            <? block content => 'body here' ?>
        </div>
        <div class="clear-both"></div>
        <div id="FooterContainer"><div id="Footer">
            Powered by <a href="http://amon.64p.org/">Amon <?= $Amon::VERSION ?></a>
        </div></div>
    </div>
</body>
</html>
