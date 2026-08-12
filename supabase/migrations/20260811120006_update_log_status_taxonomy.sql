-- Adopts the four-status taxonomy from the product pitch (Playing,
-- Backlogged, Wishlist, Completed) in place of the original
-- (playing, completed, backlog, abandoned). No "dropped"/"abandoned"
-- equivalent yet — reintroduce later if needed.
--
-- Default changes from 'completed' to 'playing': people log a game when
-- they start it, not after they finish it.

update public.logs set status = 'backlogged' where status = 'backlog';

alter table public.logs drop constraint logs_status_check;

alter table public.logs
  alter column status set default 'playing';

alter table public.logs
  add constraint logs_status_check
  check (status in ('playing', 'backlogged', 'wishlist', 'completed'));
