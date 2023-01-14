create view full_section_path
            (service_id,
             service_code,
             section_code_id,
             section_code,
             path_item_code_id)
as
select services.service_id                  as service_id,
       services.code                        as service_code,
       section_root_paths.section_code_id   as section_code_id,
       section_codes.code_id                as section_code,
       section_root_paths.path_item_code_id as path_item_code_id
from section_root_paths
         inner join section_codes on section_root_paths.section_code_id = section_codes.code_id
         inner join services on section_root_paths.service_id = services.service_id;


create view team_service_actions
            (team_id,
             team_code,
             service_id,
             service_code,
             action_code,
             section_code_id,
             section_code,
             expiration_ts,
             granted_by)
as
select teams.team_id       as team_id,
       teams.code          as team_code,
       services.service_id as service_id,
       services.code       as service_code,
       actions.code        as actions_code,
       sections.code_id    as section_code_id,
       section_codes.code  as section_code,
       roles.expiration_ts as expiration_ts,
       roles.granted_by    as granted_by
from teams
         inner join roles on teams.team_id = roles.team_id
         inner join services on roles.service_id = services.service_id
         inner join actions on roles.action_code = actions.code and services.service_id = actions.service_id
         inner join sections on roles.section_code_id = sections.code_id and services.service_id = sections.service_id
         inner join section_codes on sections.code_id = section_codes.code_id
where roles.expiration_ts > now() at time zone 'UTC';


-- 1. user_has_role_exact
-- Вывести, есть ли у пользователя ровно такая роль, полученная не транзитивно (не из секций-предков)
select exists(select 1
              from users
                       inner join team_members on users.user_id = team_members.user_id
                       inner join team_service_actions on team_members.team_id = team_service_actions.team_id
              where login = :login
                and service_code = :service_code
                and section_code = :section_code
                and action_code = :action_code);


-- 2. user_has_role_at_least
-- Вывести, есть ли у пользователя такая роль, возможно, транзитивно (из иерархии секций)
select exists(select 1
              from users
                       inner join team_members on users.user_id = team_members.user_id
                       inner join team_service_actions on team_members.team_id = team_service_actions.team_id
              where login = :login
                and service_code = :service_code
                and section_code_id in (select path_item_code_id
                                        from section_root_paths
                                        where service_code = :service_code
                                          and section_code = :section_code)
                and action_code = :action_code);


-- 3. users_can_grant_role
-- Вывести, какие пользователи могут выдать роль на заданный сервис
select users.login, users.name, users.surname
from services
         inner join team_members on services.owner_id = team_members.team_id
         inner join users on team_members.user_id = users.user_id;


-- 4. roles_expiring_tomorrow
-- Вывести, какие роли истекают в ближайшие 24 часа
select distinct team_code, service_code, action_code, section_code
from team_service_actions
where team_service_actions.expiration_ts < (now() at time zone 'UTC' + interval '1' day);


-- 5. most_granting_users
-- Вывести :limit пользователей, которые выдали больше всего ролей
select users.login, users.name, users.surname, roles_granted
from users
         inner join (select granted_by, count() as roles_granted
                     from team_service_actions
                     group by granted_by
                     order by roles_granted desc
                     limit :limit) stats on users.user_id = stats.granted_by;


-- 6. minimal_required_section
-- Вывести по двум заданным секциям минимальную, на которую можно выдать роль,
-- чтобы она проросла в обе заданные секции (если такая есть)
with common_path as (select path_item_code_id
                     from full_section_path
                     where service_code = :service_code
                       and (section_code = :first_section or section_code = :second_section)),
     common_path_parents as (select parent_code_id
                             from section_parents
                                      inner join services on section_parents.service_id = services.service_id
                             where services.code = :service_code
                               and section_parents.section_code_id in (select path_item_code_id
                                                                       from common_path)),
     minimal_section as (select path_item_code_id
                         from common_path
                         where path_item_code_id not in (select parent_code_id
                                                         from common_path_parents))
select *
from sections
         inner join services on sections.service_id = services.service_id
where sections.code_id in (select path_item_code_id from minimal_section);
