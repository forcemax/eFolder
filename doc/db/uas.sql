CREATE DATABASE IF NOT EXISTS UAS;
USE UAS;

DROP TABLE IF EXISTS `ACT_TBL`;
CREATE TABLE ACT_TBL (
  IDX_COL int(11) NOT NULL auto_increment,
  NAME_COL varchar(128) NOT NULL default '',
  DOMAIN_COL varchar(128) NOT NULL default '',
  NTNAME_COL varchar(128) NOT NULL default '',
  FLNAME_COL varchar(128) NOT NULL default '',
  ENPWD_COL text NOT NULL,
  LMPWD_COL varchar(36) NOT NULL default '',
  NTPWD_COL varchar(36) NOT NULL default '',
  PLPWD_COL varchar(128) NOT NULL default '',
  GID_COL int(11) NOT NULL default '0',
  GECOS_COL text NOT NULL,
  HOMEDIR_COL text NOT NULL,
  SHELL_COL varchar(128) NOT NULL default '',
  DRIVE_COL varchar(128) NOT NULL default '',
  LSTCHG_COL int(11) NOT NULL default '11974',
  MIN_COL int(11) NOT NULL default '0',
  MAX_COL int(11) NOT NULL default '99999',
  WARN_COL int(11) NOT NULL default '-1',
  INACT_COL int(11) NOT NULL default '-1',
  EXPIRE_COL int(11) NOT NULL default '-1',
  LOGON_COL int(11) NOT NULL default '0',
  LOGOFF_COL int(11) NOT NULL default '2147483647',
  KICKOFF_COL int(11) NOT NULL default '2147483647',
  LSTSET_COL int(11) NOT NULL default '0',
  CANCHG_COL int(11) NOT NULL default '0',
  MSTCHG_COL int(11) NOT NULL default '2147483647',
  ACB_COL varchar(13) NOT NULL default '[UX        ]',
  ACCT_COL text NOT NULL,
  PROFILE_COL text NOT NULL,
  LOGSCRT_COL text NOT NULL,
  WRKSTN_COL text NOT NULL,
  PRIMARY KEY  (NAME_COL),
  UNIQUE KEY IDX_COL (IDX_COL),
  KEY GID_COL (GID_COL)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO ACT_TBL VALUES (1,'Admin','','Admin','Administrator','!!','!!','!!','1234',100,'','','','',11978,0,99999,7,-1,-1,0,2147483647,2147483647,0,0,2147483647,'[UX        ]','','','','');

DROP TABLE IF EXISTS `GRP_TBL`;
CREATE TABLE `GRP_TBL` (
  `IDX_COL` int(11) NOT NULL auto_increment,
  `NAME_COL` varchar(128) NOT NULL default '',
  `DESC_COL` varchar(255) default NULL,
  PRIMARY KEY  (`NAME_COL`),
  UNIQUE KEY `IDX_COL` (`IDX_COL`)
) ENGINE=MyISAM AUTO_INCREMENT=10001 DEFAULT CHARSET=utf8;

INSERT INTO GRP_TBL VALUES (10000,'Domain Users','GROUP');

DROP TABLE IF EXISTS `MEM_TBL`;
CREATE TABLE MEM_TBL (
  IDX_COL int(11) NOT NULL auto_increment,
  NAME_COL varchar(128) NOT NULL default '',
  USER_COL varchar(128) NOT NULL default '',
  PRIMARY KEY  (NAME_COL,USER_COL),
  UNIQUE KEY IDX_COL (IDX_COL)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO MEM_TBL VALUES (1,'Domain Users','Admin');

