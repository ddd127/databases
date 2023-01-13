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
        foreign key (service_id, section_code_id) references sections (service_id, code_id),
    constraint fk__section_parents__service_id__parent_code_id
        foreign key (service_id, parent_code_id) references sections (service_id, code_id)
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
