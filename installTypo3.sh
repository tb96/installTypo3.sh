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
#ln -s typo3_src/index.php index.php
touch index.php
printf "
<?php
// Replacement for symlinked index.php file for TYPO3
// Author: ziegenhain@team-digital.de
// Version 1.0 – 01-02-2015

// Since we don't allow symlinks to files (security reasons, only to directories)
// we include typo3_src/index.php in this script, therefore symlink to file is
// not needed and still the current version of the TYPO3 index.php is loaded.

require 'typo3_src/index.php';" >> index.php

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
touch LocalConfiguration.php
db=datenbankname
du=datenbankuser
dp=datenbankpasswort
installPasswort='$P$CAMstFeZNWquvENdiz4fxuKMY21hVL0'
touch LocalConfiguration.php
read -p 'Datenbankname: ' db
read -p 'Datenbankuser: ' du
read -p 'Datenbankpasswort: ' dp
printf "
<?php
return [
    'BE' => [
        'debug' => false,
        'explicitADmode' => 'explicitAllow',
        'installToolPassword' => '"$installPasswort"',
        'loginSecurityLevel' => 'rsa',
    ],
    'DB' => [
        'Connections' => [
            'Default' => [
                'charset' => 'utf8',
                'dbname' => '"$db"',
                'driver' => 'mysqli',
                'host' => '127.0.0.3',
                'password' => '"$dp"',
                'port' => 3306,
                'user' => '"$du"',
            ],
        ],
    ],
    'EXT' => [
        'extConf' => [
            'dd_googlesitemap' => 'a:0:{}',
            'filemetadata' => 'a:0:{}',
            'gridelements' => 'a:2:{s:20:"additionalStylesheet";s:0:"";s:19:"nestingInListModule";s:1:"0";}',
            'realurl' => 'a:7:{s:10:"configFile";s:64:"typo3conf/ext/sitepackage/Resources/Private/Php/realurl_conf.php";s:14:"enableAutoConf";s:1:"0";s:14:"autoConfFormat";s:1:"0";s:17:"segTitleFieldList";s:0:"";s:12:"enableDevLog";s:1:"0";s:10:"moduleIcon";s:1:"0";s:19:"enableChashUrlDebug";i:0;}',
            'recycler' => 'a:0:{}',
            'rsaauth' => 'a:1:{s:18:"temporaryDirectory";s:0:"";}',
            'saltedpasswords' => 'a:2:{s:3:"BE.";a:4:{s:21:"saltedPWHashingMethod";s:41:"TYPO3\\CMS\\Saltedpasswords\\Salt\\Pbkdf2Salt";s:11:"forceSalted";i:0;s:15:"onlyAuthService";i:0;s:12:"updatePasswd";i:1;}s:3:"FE.";a:5:{s:7:"enabled";i:1;s:21:"saltedPWHashingMethod";s:41:"TYPO3\\CMS\\Saltedpasswords\\Salt\\Pbkdf2Salt";s:11:"forceSalted";i:0;s:15:"onlyAuthService";i:0;s:12:"updatePasswd";i:1;}}',
            'sitepackage' => 'a:0:{}',
        ],
    ],
    'EXTCONF' => [
        'lang' => [
            'availableLanguages' => [
                'de',
            ],
        ],
    ],
    'FE' => [
        'debug' => false,
        'loginSecurityLevel' => 'rsa',
    ],
    'GFX' => [
        'jpg_quality' => '80',
        'processor' => 'GraphicsMagick',
        'processor_allowTemporaryMasksAsPng' => false,
        'processor_colorspace' => 'RGB',
        'processor_effects' => -1,
        'processor_enabled' => true,
        'processor_path' => '/usr/bin/',
        'processor_path_lzw' => '/usr/bin/',
    ],
    'MAIL' => [
        'transport' => 'sendmail',
        'transport_sendmail_command' => '/usr/sbin/sendmail -t -i ',
        'transport_smtp_encrypt' => '',
        'transport_smtp_password' => '',
        'transport_smtp_server' => '',
        'transport_smtp_username' => '',
    ],
    'SYS' => [
        'caching' => [
            'cacheConfigurations' => [
                'extbase_object' => [
                    'backend' => 'TYPO3\\CMS\\Core\\Cache\\Backend\\Typo3DatabaseBackend',
                    'frontend' => 'TYPO3\\CMS\\Core\\Cache\\Frontend\\VariableFrontend',
                    'groups' => [
                        'system',
                    ],
                    'options' => [
                        'defaultLifetime' => 0,
                    ],
                ],
            ],
        ],
        'devIPmask' => '',
        'displayErrors' => 0,
        'enableDeprecationLog' => false,
        'encryptionKey' => '5ad2b220f239fd6aeb5615444010fd3ce1d110f6de9c5df917cdbf1c8ca8349034fa2c06272ab77b755f006c88a23187',
        'exceptionalErrors' => 20480,
        'isInitialDatabaseImportDone' => true,
        'isInitialInstallationInProgress' => false,
        'sitename' => 'New TYPO3 site',
        'sqlDebug' => 0,
        'systemLogLevel' => 2,
    ],
];

" >> LocalConfiguration.php
touch PackageStates.php
printf "
<?php
# PackageStates.php

# This file is maintained by TYPO3's package management. Although you can edit it
# manually, you should rather use the extension manager for maintaining packages.
# This file will be regenerated automatically if it doesn't exist. Deleting this file
# should, however, never become necessary if you use the package commands.

return [
    'packages' => [
        'core' => [
            'packagePath' => 'typo3/sysext/core/',
        ],
        'extbase' => [
            'packagePath' => 'typo3/sysext/extbase/',
        ],
        'fluid' => [
            'packagePath' => 'typo3/sysext/fluid/',
        ],
        'install' => [
            'packagePath' => 'typo3/sysext/install/',
        ],
        'frontend' => [
            'packagePath' => 'typo3/sysext/frontend/',
        ],
        'fluid_styled_content' => [
            'packagePath' => 'typo3/sysext/fluid_styled_content/',
        ],
        'info' => [
            'packagePath' => 'typo3/sysext/info/',
        ],
        'info_pagetsconfig' => [
            'packagePath' => 'typo3/sysext/info_pagetsconfig/',
        ],
        'extensionmanager' => [
            'packagePath' => 'typo3/sysext/extensionmanager/',
        ],
        'lang' => [
            'packagePath' => 'typo3/sysext/lang/',
        ],
        'setup' => [
            'packagePath' => 'typo3/sysext/setup/',
        ],
        'rte_ckeditor' => [
            'packagePath' => 'typo3/sysext/rte_ckeditor/',
        ],
        'rsaauth' => [
            'packagePath' => 'typo3/sysext/rsaauth/',
        ],
        'saltedpasswords' => [
            'packagePath' => 'typo3/sysext/saltedpasswords/',
        ],
        'func' => [
            'packagePath' => 'typo3/sysext/func/',
        ],
        'wizard_crpages' => [
            'packagePath' => 'typo3/sysext/wizard_crpages/',
        ],
        'wizard_sortpages' => [
            'packagePath' => 'typo3/sysext/wizard_sortpages/',
        ],
        'about' => [
            'packagePath' => 'typo3/sysext/about/',
        ],
        'backend' => [
            'packagePath' => 'typo3/sysext/backend/',
        ],
        'belog' => [
            'packagePath' => 'typo3/sysext/belog/',
        ],
        'beuser' => [
            'packagePath' => 'typo3/sysext/beuser/',
        ],
        'context_help' => [
            'packagePath' => 'typo3/sysext/context_help/',
        ],
        'cshmanual' => [
            'packagePath' => 'typo3/sysext/cshmanual/',
        ],
        'documentation' => [
            'packagePath' => 'typo3/sysext/documentation/',
        ],
        'felogin' => [
            'packagePath' => 'typo3/sysext/felogin/',
        ],
        'filelist' => [
            'packagePath' => 'typo3/sysext/filelist/',
        ],
        'filemetadata' => [
            'packagePath' => 'typo3/sysext/filemetadata/',
        ],
        'form' => [
            'packagePath' => 'typo3/sysext/form/',
        ],
        'impexp' => [
            'packagePath' => 'typo3/sysext/impexp/',
        ],
        'lowlevel' => [
            'packagePath' => 'typo3/sysext/lowlevel/',
        ],
        'recordlist' => [
            'packagePath' => 'typo3/sysext/recordlist/',
        ],
        'recycler' => [
            'packagePath' => 'typo3/sysext/recycler/',
        ],
        'reports' => [
            'packagePath' => 'typo3/sysext/reports/',
        ],
        'scheduler' => [
            'packagePath' => 'typo3/sysext/scheduler/',
        ],
        'sv' => [
            'packagePath' => 'typo3/sysext/sv/',
        ],
        'sys_note' => [
            'packagePath' => 'typo3/sysext/sys_note/',
        ],
        't3editor' => [
            'packagePath' => 'typo3/sysext/t3editor/',
        ],
        'tstemplate' => [
            'packagePath' => 'typo3/sysext/tstemplate/',
        ],
        'viewpage' => [
            'packagePath' => 'typo3/sysext/viewpage/',
        ],
        'dd_googlesitemap' => [
            'packagePath' => 'typo3conf/ext/dd_googlesitemap/',
        ],
        'gridelements' => [
            'packagePath' => 'typo3conf/ext/gridelements/',
        ],
        'realurl' => [
            'packagePath' => 'typo3conf/ext/realurl/',
        ],
        'sitepackage' => [
            'packagePath' => 'typo3conf/ext/sitepackage/',
        ],
    ],
    'version' => 5,
];

" >> PackageStates.php

touch ENABLE_INSTALL_TOOL
mkdir ext
cd ext

mkdir sitepackage
cd sitepackage
git init > /dev/null
git pull https://github.com/teamdigitalde/TYPO3_EXT_Skeleton > /dev/null 2>&1

mysql -u $du -p$dp --default_character_set utf8 -h 127.0.0.3 $db < kickstart.sql

cd ../
mkdir gridelements
cd gridelements
git init > /dev/null
git pull https://github.com/TYPO3-extensions/gridelements > /dev/null 2>&1

cd ../
mkdir dd_googlesitemap
cd dd_googlesitemap
git init > /dev/null
git pull https://github.com/dmitryd/typo3-dd_googlesitemap > /dev/null 2>&1

cd ../
mkdir realurl
cd realurl
git init > /dev/null
git pull https://github.com/dmitryd/typo3-realurl > /dev/null 2>&1

echo " "
echo "Done. Feel free to buy me a Beer :-)"
echo " "
echo "Now you can call the InstallTool and continue Installing TYPO3"
