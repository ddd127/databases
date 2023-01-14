create table users
(
    user_id int         not null,
    login   varchar(32) not null,
    name    varchar(64) not null,
    surname varchar(64) not null,

    constraint pk__users primary key (user_id),

    constraint uq__users__login unique (login)
);

create table teams
(
    team_id int          not null,
    code    varchar(32)  not null,
    name    varchar(256) not null,

    constraint pk__teams primary key (team_id),

    constraint uq__teams__code unique (code)
);

create table team_members
(
    user_id int not null,
    team_id int not null,

    constraint pk__team_members primary key (user_id, team_id),

    constraint fk__team_members__user_id foreign key (user_id) references users (user_id),
    constraint fk__team_members__team_id foreign key (team_id) references teams (team_id)
);

create table services
(
    service_id int          not null,
    code       varchar(32)  not null,
    name       varchar(256) not null,
    owner_id   int          not null,

    constraint pk__services primary key (service_id),

    constraint uq__services__code unique (code),

    constraint fk__services__owner_id foreign key (owner_id) references teams (team_id)
);

create table actions
(
    service_id int          not null,
    code       varchar(32)  not null,
    name       varchar(256) not null,

    constraint pk__actions primary key (service_id, code),

    constraint fk__actions__service_id foreign key (service_id) references services (service_id)
);

create table section_codes
(
    code_id int         not null,
    code    varchar(32) not null,

    constraint pk__section_codes primary key (code_id),

    constraint uq__section_codes unique (code)
);

create table sections
(
    service_id int          not null,
    code_id    int          not null,
    name       varchar(256) not null,

    constraint pk__sections primary key (service_id, code_id),

    constraint fk__sections__service_id foreign key (service_id) references services (service_id),
    constraint fk__sections__code_id foreign key (code_id) references section_codes (code_id)
);

create table section_parents
(
    service_id      int not null,
    section_code_id int not null,
    parent_code_id  int not null,

    constraint pk__section_parents primary key (service_id, section_code_id),

    constraint fk__section_parents__service_id__section_code_id
        foreign key (service_id, section_code_id) references sections (service_id, code_id)
            on delete cascade,
    constraint fk__section_parents__service_id__parent_code_id
        foreign key (service_id, parent_code_id) references sections (service_id, code_id)
            on delete restrict
);

create table section_root_paths
(
    service_id        int not null,
    section_code_id   int not null,
    path_item_code_id int not null,

    constraint pk__section_root_path primary key (service_id, section_code_id, path_item_code_id),

    constraint fk__section_root_path__service_id__section_code_id
        foreign key (service_id, section_code_id) references sections (service_id, code_id)
            on delete cascade,
    constraint fk__section_root_path__service_id__ancestor_code_id
        foreign key (service_id, path_item_code_id) references sections (service_id, code_id)
            on delete restrict
);

create table roles
(
    team_id         int         not null,
    service_id      int         not null,
    section_code_id int         not null,
    action_code     varchar(32) not null,
    granted_by      int         not null,
    expiration_ts   timestamp   null,

    constraint pk__roles primary key (team_id, service_id, section_code_id, action_code),

    constraint fk__roles__team_id foreign key (team_id) references teams (team_id),
    constraint fk__roles__service_id__section_code_id
        foreign key (service_id, section_code_id) references sections (service_id, code_id),
    constraint fk__roles__service_id__action_code
        foreign key (service_id, action_code) references actions (service_id, code),
    constraint fk__roles__granted_by foreign key (granted_by) references users (user_id)
);

-- constraint trigger для таблицы section_parents --

create function fn__section_parents__cycle_check() returns trigger
as
$section_parents__update_validation$
begin
    if exists(select *
              from section_root_paths
              where service_id = new.service_id
                and section_code_id = new.parent_code_id
                and path_item_code_id = new.section_code_id) then
        raise exception 'Can not execute update - cycle detected';
    end if;
    return new;
end;
$section_parents__update_validation$ language plpgsql;

create trigger tg__section_parents__cycle_check
    before insert or update
    on section_parents
    for each row
execute function fn__section_parents__cycle_check();


-- функции и триггеры, обновляющие section_ancestors --

create function fn__sections__new_section() returns trigger
as
$sections__new_section$
begin
    insert into section_root_paths (service_id, section_code_id, path_item_code_id)
    values (new.service_id, new.code_id, new.code_id);
    return null;
end;
$sections__new_section$ language plpgsql;

create trigger tg__sections__new_section
    after insert or update
    on sections
    for each row
execute function fn__sections__new_section();


create procedure fn__section_ancestors__add_edge(
    section_parent_record record
) as
$section_ancestors__add_edge$
begin
    with new_ancestors as (select path_item_code_id
                           from section_root_paths
                           where service_id = section_parent_record.service_id
                             and section_code_id = section_parent_record.parent_code_id),
         subtree as (select service_id, section_code_id
                     from section_root_paths
                     where service_id = section_parent_record.service_id
                       and path_item_code_id = section_parent_record.section_code_id)
    insert
    into section_root_paths(service_id, section_code_id, path_item_code_id)
    select service_id, section_code_id, path_item_code_id
    from subtree
             cross join new_ancestors;
    return;
end;
$section_ancestors__add_edge$ language plpgsql;

create procedure fn__section_ancestors__delete_edge(
    section_parent_record record
) as
$section_ancestors__remove_edge$
begin
    with old_ancestors as (select path_item_code_id
                           from section_root_paths
                           where service_id = section_parent_record.service_id
                             and section_code_id = section_parent_record.section_code_id
                             and path_item_code_id != section_parent_record.section_code_id),
         subtree as (select service_id, section_code_id
                     from section_root_paths
                     where service_id = section_parent_record.service_id
                       and path_item_code_id = section_parent_record.section_code_id)
    delete
    from section_root_paths
    where section_root_paths.path_item_code_id in
          (select path_item_code_id from old_ancestors)
      and (section_root_paths.service_id, section_root_paths.section_code_id) in
          (select service_id, section_code_id from subtree);
    return;
end;
$section_ancestors__remove_edge$ language plpgsql;


create function fn__section_parents__insert__ancestors() returns trigger
as
$section_parents__insert$
begin
    call fn__section_ancestors__add_edge(new);
    return null;
end;
$section_parents__insert$ language plpgsql;

create function fn__section_parents__delete__ancestors() returns trigger
as
$section_parents__delete$
begin
    call fn__section_ancestors__delete_edge(old);
    return null;
end;
$section_parents__delete$ language plpgsql;

create function fn__section_parents__update__ancestors() returns trigger
as
$section_parents__update$
begin
    call fn__section_ancestors__delete_edge(old);
    call fn__section_ancestors__add_edge(new);
    return null;
end;
$section_parents__update$ language plpgsql;


create trigger tg__section_parents__insert__ancestors
    after insert
    on section_parents
    for each row
execute function fn__section_parents__insert__ancestors();

create trigger tg__section_parents__delete__ancestors
    after delete
    on section_parents
    for each row
execute function fn__section_parents__delete__ancestors();

create trigger tg__section_parents__update__ancestors
    after update
    on section_parents
    for each row
execute function fn__section_parents__update__ancestors();
