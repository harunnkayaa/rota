-- delete_my_account() removes the caller and all their data — and nobody
-- else's.

begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');

insert into public.categories (id, user_id, name, icon_key) values
  ('10000000-0000-0000-0000-00000000000a',
   '00000000-0000-0000-0000-00000000000a', 'A', 'code'),
  ('10000000-0000-0000-0000-00000000000b',
   '00000000-0000-0000-0000-00000000000b', 'B', 'code');

set local role anon;
select throws_ok(
  $$ select public.delete_my_account() $$,
  '42501',
  null,
  'signed-out callers cannot use it'
);

set local role authenticated;
set local "request.jwt.claims" to
  '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';
select lives_ok(
  $$ select public.delete_my_account() $$,
  'a signed-in user can delete their account'
);

reset role;
select is(
  (select count(*)::int from auth.users
    where id = '00000000-0000-0000-0000-00000000000a'),
  0,
  'the caller''s account and data are gone'
);
select is(
  (select count(*)::int from public.categories
    where user_id = '00000000-0000-0000-0000-00000000000b'),
  1,
  'other users are untouched'
);

select * from finish();
rollback;
