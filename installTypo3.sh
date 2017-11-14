#!/bin/bash

url="http://get.typo3.org/8"
target="t3latest.tar.gz"
workingdirectory=${PWD}

clear

echo "Getting the TYPO3 Sources from ${url}, writing to ${target}"
# get the sourcec
wget $url -O $target --no-check-certificate > /dev/null 2>&1
# untar the tar ball
tar -xzf $target > /dev/null
# remove tar ball
rm -f $target
# make cms directory
mkdir cms
# rename sources directory
mv typo3_src-* typo3_src

#copy .htaccess
cp typo3_src/_.htaccess cms/.htaccess

#prevent accessing sql-files in browser
printf '
# Basic security checks
# - no access for .git repository dir
RewriteRule ^(.*/)?\.git+ - [R=404,L]
# - Restrict access to sql dumps
RewriteRule ^.*(\.sql)$ - [F]' >> cms/.htaccess

#add Apache-Tuning to htaccess
printf '
<IfModule mod_rewrite.c>
# rewrite non-www on HTTP connection
RewriteCond %%{HTTPS} off
RewriteCond %%{HTTP_HOST} !^www\.(.*)$ [NC]
RewriteRule ^(.*)$ http://www.%%{HTTP_HOST}/$1 [R=301,L]

# rewrite non-www on HTTPS connection
RewriteCond %%{HTTPS} on
RewriteCond %%{HTTP_HOST} !^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://www.%%{HTTP_HOST}/$1 [R=301,L]

# rewrite dd_googlesitemap
RewriteRule ^sitemap.xml$ /index.php?eID=dd_googlesitemap [L]
</IfModule>

#activate browser caching
<IfModule mod_expires.c>
 ExpiresActive On 
 ExpiresByType text/css "access plus 1 week" 
 ExpiresByType application/javascript "access plus 1 month" 
 ExpiresByType application/x-javascript "access plus 1 month" 
 ExpiresByType image/gif "access plus 1 month" 
 ExpiresByType image/jpeg "access plus 1 month" 
 ExpiresByType image/png "access plus 1 month" 
 ExpiresByType image/x-icon "access plus 1 year" 
 ExpiresByType application/x-shockwave-flash "access plus 1 months" 
</IfModule>

#enable Gzip compression
<IfModule mod_deflate.c>
 <FilesMatch "\\.(js|css|html|xml|txt|php)$">
 SetOutputFilter DEFLATE
 </FilesMatch> 
</IfModule>

#set etag headers
<IfModule mod_headers.c> 
 Header unset ETag 
 FileETag None 
</IfModule>' >> cms/.htaccess

#basic access-restriction (beta/seite;)
printf "
# basic access-restriction (beta/seite;)
AuthName 'Geschützter Bereich'
AuthType Basic
AuthUserFile ${workingdirectory}/.htpasswd
require valid-user" >> cms/.htaccess

#htpasswd
printf 'beta:$1$$.OPcLRctp0tpQ81Db9tKP/' >> .htpasswd

#change to cms directory
cd cms/

#create index.php
ln -s typo3_src/index.php index.php

#create fileadmin, user_upload and typo3conf
mkdir fileadmin
cd fileadmin
mkdir user_upload
cd ../
mkdir typo3conf

#create symlinks
ln -s ../typo3_src/ typo3_src
ln -s typo3_src/typo3 typo3

#create empty FIRST_INSTALL file
touch FIRST_INSTALL

#create a git repository
git init > /dev/null

#pull TYPO3 Skeleton from github
#git pull https://github.com/teamdigitalde/TYPO3_Skeleton.git > /dev/null 2>&1

#mkdir typo3conf
cd typo3conf
touch ENABLE_INSTALL_TOOL
mkdir ext
cd ext
mkdir powermail
cd powermail
git init > /dev/null
git pull git://git.typo3.org/TYPO3CMS/Extensions/powermail.git > /dev/null 2>&1

cd ../
mkdir sitepackage
cd sitepackage
git init > /dev/null
git pull https://github.com/teamdigitalde/TYPO3_EXT_Skeleton > /dev/null 2>&1

cd ../
mkdir gridelements
cd gridelements
git init > /dev/null
git pull https://github.com/TYPO3-extensions/gridelements.git > /dev/null 2>&1

cd ../
mkdir dd_googlesitemap
cd dd_googlesitemap
git init > /dev/null
git pull https://github.com/dmitryd/typo3-dd_googlesitemap.git > /dev/null 2>&1

cd ../
mkdir realurl
cd realurl
git init > /dev/null
git pull https://git.typo3.org/TYPO3CMS/Extensions/realurl.git > /dev/null 2>&1

echo " "
echo "Done. Feel free to buy me a Beer :-)"
echo " "
echo "Now you can call the InstallTool and continue Installing TYPO3"
