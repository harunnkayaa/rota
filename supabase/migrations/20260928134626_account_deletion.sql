-- Account deletion (project rules: "Hesap silme tüm ilgili kişisel veriyi
-- kapsamalıdır").
--
-- A signed-in user cannot delete their own progress entries (append-only),
-- so deletion runs as a narrowly scoped SECURITY DEFINER function: it can
-- only ever delete the caller's own auth user. Every table references
-- auth.users with ON DELETE CASCADE, so all of their rows go with it.

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not signed in' using errcode = '42501';
  end if;
  delete from auth.users where id = me;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
