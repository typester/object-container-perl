use inc::Module::Install;
name 'Object-Container';
all_from 'lib/Object/Container.pm';

requires 'Any::Moose' => '0.07';
requires 'Class::Singleton';
requires 'Exporter::AutoClean';

test_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
