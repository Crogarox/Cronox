use inc::Module::Install;
name 'Cronox';
all_from 'lib/Cronox.pm';

requires 'Class::Trigger';
requires 'Class::Accessor::Lite';
#requires 'FindBin::libs';
requires 'Path::Class';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';

# Plugin::Notify::Mail
requires 'Email::MIME';
requires 'Email::MIME::Creator';
requires 'Email::Send';

# Plugin::Recorder::Database
requires 'SQL::Maker';

tests 't/*.t';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::mysqld';

install_script 'bin/cronox';
WriteAll;
