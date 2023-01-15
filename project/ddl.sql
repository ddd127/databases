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
    constraint fk__section_root_path__service_id__path_item_code_id
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


-- indices --
-- отмечу, что индексы на primary и unique postgres создает сам,
-- поэтому явных индексов на них я не делал.

-- Btree иногда выбирал там, где более одного параметра,
-- чтобы при запросе по префиксу параметров индекс тоже работал.

-- foreign key indices

create index ix__team_members__user_id on team_members using hash (user_id);
create index ix__team_members__team_id on team_members using hash (team_id);

create index ix__services__owner_id on services using hash (owner_id);

create index ix__actions__actions_id on actions using hash (service_id);
create index ix__actions__service_id on sections using hash (service_id);

create index ix__section_parents__service_id__parent_code_id
    on section_parents using btree (service_id, parent_code_id);

create index ix__section_root_paths__service_id__section_code_id
    on section_root_paths using btree (service_id, section_code_id);
create index ix__section_root_paths__service_id__path_item_code_id
    on section_root_paths using btree (service_id, path_item_code_id);

create index ix__roles__team_id on roles using hash (team_id);
create index ix__roles__service_id__section_code_id on roles using btree (service_id, section_code_id);
create index ix__roles__service_id__action_code on roles using btree (service_id, action_code);
create index ix__roles__granted_by on roles using hash (granted_by);

-- индексы для запросов
-- индекс на expiration_ts using btree
-- нужен для team_service_actions view,
-- поскольку там происходит фильтрация по expiration_ts > now()
-- primary key в индекс добавлен для того,
-- чтобы запросы user_has_role_exact и user_has_role_at_least работали быстрее
-- (по идее, это самые горячие запросы в системе, поэтому для них точно надо).
create index ix__roles__expiration_ts__and_others
    on roles using btree (expiration_ts, service_id, team_id, action_code, section_code_id) include (granted_by);

-- покрывающие индексы для join-ов (primary key и так будет btree в обратную сторону)
-- индексов получилось довольно много, но за счет такого их количества,
-- team_service_actions view вообще не должно заходить в таблицы,
-- поскольку все значения полей можно получить из join индексов
-- и ix__roles__expiration_ts__and_others
create index ix__team_members__team_id__user_id on team_members using btree (user_id, team_id);
create index ix__service__code__service_id on services using btree (code, service_id);
create index ix__section_codes__code__code_id on section_codes using btree (code, code_id);
create index ix__sections__code_id__service_id on sections using btree (code_id, service_id);
create index ix__actions__code__service_id on actions using btree (code, service_id);
create index ix__teams__code__team_id on teams using btree (code, team_id);


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
        raise 'Can not execute update - cycle detected';
    end if;
    return new;
end;
$section_parents__update_validation$ language plpgsql;

create trigger tg__section_parents__cycle_check
    before insert or update
    on section_parents
    for each row
execute function fn__section_parents__cycle_check();


-- функции и триггеры, обновляющие section_root_paths --

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


-- read committed --
create procedure fn__section_root_paths__add_edge(
    section_parent_record record
) as
$section_root_paths__add_edge$
begin
    with new_root_paths as (select path_item_code_id
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
             cross join new_root_paths;
    return;
end;
$section_root_paths__add_edge$ language plpgsql;

-- read committed --
create procedure fn__section_root_paths__delete_edge(
    section_parent_record record
) as
$section_root_paths__remove_edge$
begin
    with old_root_paths as (select path_item_code_id
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
          (select path_item_code_id from old_root_paths)
      and (section_root_paths.service_id, section_root_paths.section_code_id) in
          (select service_id, section_code_id from subtree);
    return;
end;
$section_root_paths__remove_edge$ language plpgsql;


-- read committed --
create function fn__section_parents__insert__root_paths() returns trigger
as
$section_parents__insert$
begin
    call fn__section_root_paths__add_edge(new);
    return null;
end;
$section_parents__insert$ language plpgsql;

-- read committed --
create function fn__section_parents__delete__root_paths() returns trigger
as
$section_parents__delete$
begin
    call fn__section_root_paths__delete_edge(old);
    return null;
end;
$section_parents__delete$ language plpgsql;

-- read committed --
create function fn__section_parents__update__root_paths() returns trigger
as
$section_parents__update$
begin
    call fn__section_root_paths__delete_edge(old);
    call fn__section_root_paths__add_edge(new);
    return null;
end;
$section_parents__update$ language plpgsql;


create trigger tg__section_parents__insert__root_paths
    after insert
    on section_parents
    for each row
execute function fn__section_parents__insert__root_paths();

create trigger tg__section_parents__delete__root_paths
    after delete
    on section_parents
    for each row
execute function fn__section_parents__delete__root_paths();

create trigger tg__section_parents__update__root_paths
    after update
    on section_parents
    for each row
execute function fn__section_parents__update__root_paths();
