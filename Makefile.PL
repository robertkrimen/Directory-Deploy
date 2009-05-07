use inc::Module::Install;

name     'Directory-Deploy';
all_from 'lib/Directory/Deploy.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

