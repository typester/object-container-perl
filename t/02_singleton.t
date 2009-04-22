use Test::Base;

plan tests => 3;

use Object::Container;

ok(Object::Container->register('FileHandle'), 'register ok');
isa_ok(Object::Container->get('FileHandle'), 'FileHandle' );

is(
    Object::Container->get('FileHandle'),
    Object::Container->get('FileHandle'),
    'same object ok',
);
