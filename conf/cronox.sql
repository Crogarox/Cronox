CREATE TABLE history (
  id int(10) unsigned NOT NULL auto_increment,
  hostname varchar(32) NOT NULL,
  script_name varchar(255) NOT NULL,
  script_path varchar(255) NOT NULL,
  command varchar(255) NOT NULL,
  exit_code tinyint(4) DEFAULT 0,
  output text,
  started_on int(10) unsigned NOT NULL,
  finished_on int(10) unsigned NOT NULL,
  PRIMARY key (id),
  KEY history_hostname (hostname),
  KEY history_script_name (script_name),
  KEY history_started_on (started_on),
  KEY history_script_name_and_started_on (script_name, started_on)
) ENGINE=InnoDB CHARSET=utf8;
