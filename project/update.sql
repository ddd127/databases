create procedure fn__check_owner_access(
    actor_login varchar(32),
    service_code varchar(32)
) as
$has_owner_access$
begin
    if not exists(select 1
                  from services
                           inner join teams on services.owner_id = teams.team_id
                           inner join team_members on teams.team_id = team_members.team_id
                           inner join users on team_members.user_id = users.user_id
                  where users.login = actor_login) then
        raise 'User % has no owner access to service %', actor_login, service_code;
    end if;
    return;
end;
$has_owner_access$ language plpgsql;


create procedure fn__grant_role(
    actor_login varchar(32),
    team_code varchar(32),
    service_code varchar(32),
    action_code varchar(32),
    section_code varchar(32),
    expiration_ts timestamp
) as
$grant_role$
begin
    call fn__check_owner_access(actor_login, service_code);

    insert into roles(team_id, service_id, section_code_id, action_code, granted_by, expiration_ts)
    select teams.team_id, services.service_id, section_codes.code_id, actions.code, users.user_id, expiration_ts
    from services
             inner join actions on services.service_id = actions.service_id
             inner join sections on services.service_id = sections.service_id
             inner join section_codes on sections.code_id = section_codes.code_id
             cross join teams
             cross join users
    where services.code = service_code
      and actions.code = action_code
      and section_codes.code = section_code
      and teams.code = team_code
      and users.login = actor_login;

    return;
end;
$grant_role$ language plpgsql;


create procedure fn__extend_role(
    actor_login varchar(32),
    team_code varchar(32),
    service_code varchar(32),
    action_code_arg varchar(32),
    section_code varchar(32),
    expiration_ts_arg timestamp
) as
$extend_role$
begin
    call fn__check_owner_access(actor_login, service_code);

    update roles
    set expiration_ts = expiration_ts_arg,
        granted_by    = users.user_id
    from teams,
         services,
         actions,
         sections,
         section_codes,
         users
    where roles.team_id = teams.team_id
      and roles.service_id = services.service_id
      and roles.action_code = actions.code
      and roles.section_code_id = sections.code_id

      and services.service_id = actions.service_id
      and services.service_id = sections.service_id
      and sections.code_id = section_codes.code_id

      and teams.code = team_code
      and services.code = service_code
      and actions.code = action_code_arg
      and section_codes.code = section_code
      and users.login = actor_login;

    return;
end;
$extend_role$ language plpgsql;


create procedure fn__revoke_role(
    actor_login varchar(32),
    team_code varchar(32),
    service_code varchar(32),
    action_code_arg varchar(32),
    section_code varchar(32)
) as
$revoke_role$
begin
    call fn__check_owner_access(actor_login, service_code);

    delete
    from roles
        using teams, services, actions, sections, section_codes
    where roles.team_id = teams.team_id
      and roles.service_id = services.service_id
      and roles.action_code = actions.code
      and roles.section_code_id = sections.code_id

      and services.service_id = actions.service_id
      and services.service_id = sections.service_id
      and sections.code_id = section_codes.code_id

      and teams.code = team_code
      and services.code = service_code
      and actions.code = action_code_arg
      and section_codes.code = section_code;

    return;
end;
$revoke_role$ language plpgsql;


create procedure fn__change_service_owner(
    actor_login varchar(32),
    team_code varchar(32),
    service_code varchar(32)
) as
$change_service_owner$
begin
    call fn__check_owner_access(actor_login, service_code);

    update services
    set owner_id = team_id
    from teams
    where teams.code = team_code
      and services.code = service_code;

    return;
end;
$change_service_owner$ language plpgsql;
