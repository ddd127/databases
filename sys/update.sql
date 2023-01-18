----------------------------------------
-- Procedures, functions and Triggers --
----------------------------------------

-- READ COMMITTED
create or replace function update_gained_awards() returns trigger
    language plpgsql as
$$
begin
    insert into gained_awards
    select a.id as award_id, new.user_id as user_id, now() as timestamp, (max(ga.place) + 1) as place
    from awards a
             join gained_awards ga on a.id = ga.award_id
    where a.competition_id = (select distinct c.id
                              from competitions c
                                       join tracks t on c.id = t.competition_id
                                       join tasks t2 on t.id = t2.track_id
                              where t2.id = new.task_id)
      and a.tasks_to_gain <= (select sum(auitbt.count_completed_tasks)
                              from competitions c
                                       join tracks t on c.id = t.competition_id
                                       join active_users_in_track_by_tasks auitbt on t.id = auitbt.track_id
                              where auitbt.user_id = new.user_id)
    group by a.id
    on conflict do nothing;
    return null;
end;
$$;

-- Триггер, который выдает награды по числу выполненных заданий
create or replace trigger update_gained_awards_trigger
    after insert
    on completed_tasks
    for each row
execute procedure update_gained_awards();

create type competition_dates as
(
    start_date timestamp,
    end_date   timestamp
);

-- READ COMMITTED
create or replace function mark_complete(_user_id int, _task_id int) returns bool
    language plpgsql as
$$
declare
    dates competition_dates = (select (c.start_date, c.end_date)
                               from competitions c
                                        join tracks t on c.id = t.competition_id
                                        join tasks t2 on t.id = t2.track_id
                               where t2.id = _task_id
                               limit 1);
begin
    if (now() >= dates.start_date and now() <= dates.end_date) then
        begin
            insert into completed_tasks (user_id, task_id, timestamp)
            values (_user_id, _task_id, now());
            return true;
        end;
    else
        return false;
    end if;
end;
$$;

-- READ COMMITTED
create or replace procedure remove_weak_members(_team_id int, n int)
    language plpgsql as
$$
declare
    cur_competition int = (select distinct c.id
                           from competitions c
                                    join teams t2 on c.id = t2.competition_id and t2.id = _team_id);
begin
    delete
    from team_members tm
    where tm.team_id = _team_id
      and tm.user_id in
          (select tm2.user_id
           from team_members tm2
                    join (select aubt.user_id
                          from competitions c
                                   join tracks t on c.id = t.competition_id
                                   join active_users_in_track_by_tasks aubt on t.id = aubt.track_id
                          where c.id = cur_competition
                          group by aubt.user_id
                          having sum(aubt.count_completed_tasks) < n) as weak_users
                         on weak_users.user_id = tm2.user_id and tm2.team_id = _team_id);
end;
$$;

create type raw_award as
(
    name        varchar(128),
    description text,
    rank        rank
);

-- READ COMMITTED
create or replace procedure generate_awards(_competition_id int, n int, award_list raw_award[])
    language plpgsql as
$$
declare
    tasks_cnt     int = (select count(t2.id)
                         from competitions c
                                  join tracks t on c.id = t.competition_id and c.id = _competition_id
                                  join tasks t2 on t.id = t2.track_id);
    step          int = ceil(tasks_cnt::float / n);
    current_award raw_award;
    j             int = 1;
begin
    for i in 1..n - 1 by 1
        loop
            current_award := award_list[i];
            insert into awards (name, description, rank, tasks_to_gain, competition_id)
            values (current_award.name, current_award.description, current_award.rank, j, _competition_id);
            j := j + step;
        end loop;

    current_award := award_list[n];
    insert into awards (name, description, rank, tasks_to_gain, competition_id)
    values (current_award.name, current_award.description, current_award.rank, tasks_cnt, _competition_id);
end;
$$;

create type teams_stats as
(
    teams_no   int,
    members_no int
);

-- SERIALIZABLE
create or replace procedure rebalance_teams(_competition_id int)
    language plpgsql as
$$
declare
    stats                teams_stats = (select (count(sub.team_id), sum(sub.sum_members))
                                        from (select t.id as team_id, count(tm.user_id) as sum_members
                                              from competitions c
                                                       join teams t on c.id = t.competition_id and c.id = _competition_id
                                                       join team_members tm on t.id = tm.team_id
                                              group by t.id) as sub);
    size                 int         = ceil(stats.members_no::float / stats.teams_no);
    teams_cursor_1 cursor for (select t.id
                               from competitions c
                                        join teams t on c.id = t.competition_id and c.id = _competition_id);
    teams_cursor_2 cursor for (select t.id
                               from competitions c
                                        join teams t on c.id = t.competition_id and c.id = _competition_id);
    excessive_member     record;
    need_to_fill_in      int;
    moved_members_cursor refcursor;
    next_moved           record;
begin
    create temp table moved_members
    (
        user_id     int,
        old_team_id int
    );

    for cur_team_id in teams_cursor_1
        loop
            for excessive_member in
                select tm.user_id
                from (select user_id from team_members where team_id = cur_team_id.id) tm
                         left join (select user_id from team_members where team_id = cur_team_id.id limit size) tm2
                                   on tm.user_id = tm2.user_id
                where tm2.user_id is null
                loop
                    insert into moved_members (user_id, old_team_id) values (excessive_member.user_id, cur_team_id.id);
                end loop;
        end loop;

    open moved_members_cursor for (select user_id, old_team_id from moved_members);
    for cur_team_id in teams_cursor_2
        loop
            need_to_fill_in := size -
                               (select count(user_id) from team_members tm where tm.team_id = cur_team_id.id)::int;
            for _ in 1..need_to_fill_in
                loop
                    fetch moved_members_cursor into next_moved;
                    update team_members
                    set team_id = cur_team_id.id
                    where user_id = next_moved.user_id
                      and team_id = next_moved.old_team_id;
                end loop;
        end loop;

    close moved_members_cursor;

    drop table moved_members;
end;
$$;


-------------
-- Queries --
-------------

-- RebalanceTeams, SERIALIZABLE
-- перебаллансировка команд в соревновании, таким образом, чтобы разрыв в численности участников был минимален
call rebalance_teams(:CompetitionId);

-- RemoveWeakMembers, READ COMMITTED
-- удаление участников из команды, которые выполнили менее n заданий
call remove_weak_members(:TeamId, :n);

-- GenerateAwards, READ COMMITTED
-- создать n наград для заданий в соревновании, равномерно распределенных по количестку этих заданий
call generate_awards(:CompetitionId, :n, :list);

-- MarkComplete, READ COMMITTED
select mark_complete(:UserId, :TaskId);

-- JoinTeam, READ COMMITTED
insert into team_members (team_id, user_id)
values (:TeamId, :UserId);

-- LeaveTeam, READ COMMITTED
delete
from team_members
where team_id = :TeamId
  and user_id = :UserId;
