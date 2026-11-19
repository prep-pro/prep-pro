-- Prep.pro · v9.4 · Ajustes de segurança apontados pelo Supabase (advisors)
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.perfil_protege() from public, anon, authenticated;
revoke execute on function public.preparador_protege_destaque() from public, anon, authenticated;
revoke execute on function public.is_admin() from public, anon;
revoke execute on function public.is_pro() from public, anon;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_pro() to authenticated;
