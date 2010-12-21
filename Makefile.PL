use inc::Module::Install;
name 'Object-Container';
all_from 'lib/Object/Container.pm';

requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'parent';

recommends 'Exporter::AutoClean';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Requires';
use_test_base;
author_tests 'xt';

auto_set_repository;

WriteAll;
