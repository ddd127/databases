-----------
-- Views --
-----------

-- список пользователей с количеством выполненных заданий в треке >= 1 для каждого трека
create view active_users_in_track_by_tasks as
select u.id as user_id, t2.id as track_id, count(ct.task_id) as count_completed_tasks
from users u
         join completed_tasks ct on u.id = ct.user_id
         join tasks t on t.id = ct.task_id
         join tracks t2 on t2.id = t.track_id
group by u.id, t2.id;

-- список пользователей с количеством полученных наград в соревновании >= 1 для каждого соревнования
create view active_users_by_awards as
select u.id as user_id, c.id as competition_id, count(ga.award_id) as count_gained_awards
from users u
         join gained_awards ga on u.id = ga.user_id
         join awards a on ga.award_id = a.id
         join competitions c on c.id = a.competition_id
group by u.id, c.id;

-------------
-- Queries --
-------------

-----------------------------
-- Информация для награждения

-- FirstWeekWinners
-- пользователи, получившие хотя бы одну награду в первую неделю соревнования
select distinct ct.user_id
from competitions c
         join tracks t on c.id = t.competition_id
         join tasks t2 on t.id = t2.track_id
         join completed_tasks ct on t2.id = ct.task_id
where c.id = :CompetitionId
  and ct.timestamp <= (c.start_date + interval '6 days');

-- CompetitionWinners
-- 3 пользователя, которые первыми получили все награды в соревновании
with competition_awards as
         (select a2.id as id
          from competitions c
                   join awards a2 on c.id = a2.competition_id
          where c.id = :CompetitionId)
select users_last_award_times.user_id
from (select ga.user_id
      from competition_awards ca
               join gained_awards ga on ca.id = ga.award_id
      group by ga.user_id
      having count(ga.award_id) =
             (select count(id) as cnt from competition_awards)) as users_with_all_award
         join (select ga.user_id, max(ga.timestamp) as last_award_timestamp
               from competition_awards ca
                        join gained_awards ga on ca.id = ga.award_id
               group by ga.user_id) as users_last_award_times
              on users_with_all_award.user_id = users_last_award_times.user_id
order by users_last_award_times.last_award_timestamp
limit 3;

-- FastestGunInTheWildWest
-- пользователь, который получил больше всего наград первым
select ga.user_id
from competitions c
         join awards a on c.id = a.competition_id
         join gained_awards ga on a.id = ga.award_id
where ga.place = 1
group by ga.user_id
order by count(ga.award_id) desc, max(ga.timestamp)
limit 1;

-- BestTeams
-- команды, которые в среднем выполнили больше половины заданий в соревновании
with competition_tasks as
         (select t2.id
          from competitions c
                   join tracks t on c.id = t.competition_id
                   join tasks t2 on t.id = t2.track_id
          where c.id = :CompetitionId)
select t.id
from competitions c1
         join teams t on c1.id = t.competition_id and c1.id = :CompetitionId
         join team_members tm on t.id = tm.team_id
         join (select c2.user_id, c2.task_id
               from competition_tasks ct
                        join completed_tasks c2 on ct.id = c2.task_id) as user_completed_tasks
              on user_completed_tasks.user_id = tm.user_id
group by t.id
having count(user_completed_tasks.task_id)::float / count(distinct tm.user_id) >=
       (select count(c3.id) from competition_tasks c3)::float / 2;

-----------------------
-- Всяческие лидерборды

-- CompetitionUsersLeaderboardByTasks
-- лидерборд всех пользователей в соревновании по количеству выполненных заданий
select aubt.user_id, sum(aubt.count_completed_tasks) as count_completed_tasks
from competitions c
         join tracks t on c.id = t.competition_id
         join active_users_in_track_by_tasks aubt on t.id = aubt.track_id
where c.id = :CompetitionId
group by aubt.user_id
order by count_completed_tasks desc;

-- CompetitionUsersLeaderboardByAwards
-- лидерборд всех пользователей в соревновании по количеству полученных наград
select auba.user_id, auba.count_gained_awards
from competitions c
         join active_users_by_awards auba on c.id = auba.competition_id
where c.id = :CompetitionId
order by auba.count_gained_awards desc;

-- TrackUsersLeaderboard
-- лидерборд всех пользователей по количеству выполненных заданий в треке
select aubt.user_id, aubt.count_completed_tasks
from tracks t
         join active_users_in_track_by_tasks aubt on t.id = aubt.track_id
where t.id = :TrackId
order by aubt.count_completed_tasks desc;

-- CompetitionTeamsLeaderboardByTasks
-- лидерборд всех команд в соревновании по количеству выполненных заданий
select tm.team_id, sum(aubt.count_completed_tasks) as count_completed_tasks
from competitions c
         join tracks t on c.id = t.competition_id
         join active_users_in_track_by_tasks aubt on t.id = aubt.track_id
         join teams t2 on c.id = t2.competition_id
         join team_members tm on aubt.user_id = tm.user_id and t2.id = tm.team_id
where c.id = :CompetitionId
group by tm.team_id
order by count_completed_tasks desc;

-- CompetitionTeamsLeaderboardByAwards
-- лидерборд всех команд в соревновании по количеству полученных наград
select tm.team_id, sum(auba.count_gained_awards) as count_gained_awards
from competitions c
         join active_users_by_awards auba on c.id = auba.competition_id
         join teams t2 on c.id = t2.competition_id
         join team_members tm on auba.user_id = tm.user_id and t2.id = tm.team_id
where c.id = :CompetitionId
group by tm.team_id
order by count_gained_awards desc;

-- TrackTeamsLeaderboard
-- лидерборд всех команд по количеству полученных наград в треке
select tm.team_id, sum(aubt.count_completed_tasks) as count_completed_tasks
from competitions c
         join tracks t on c.id = t.competition_id
         join active_users_in_track_by_tasks aubt on t.id = aubt.track_id
         join teams t2 on c.id = t2.competition_id
         join team_members tm on aubt.user_id = tm.user_id and t2.id = tm.team_id
where t.id = :TrackId
group by tm.team_id
order by count_completed_tasks desc;

---------------------------------------
-- информация для страницы пользователя

-- UserCompletedTasks
-- все задания выполненные пользователем в соревновании
select ct.task_id
from competitions c
         join tracks t on c.id = t.competition_id
         join tasks t2 on t.id = t2.track_id
         join completed_tasks ct on t2.id = ct.task_id
where c.id = :CompetitionId
  and ct.user_id = :UserId;

-- UserGainedAwards
-- все награды полученные пользователем в соревновании
select ga.award_id
from competitions c
         join awards a on c.id = a.competition_id
         join gained_awards ga on ga.award_id = a.id
where c.id = :CompetitionId
  and ga.user_id = :UserId;
