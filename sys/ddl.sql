create table if not exists competitions
(
    id          int primary key,
    name        varchar(128) not null,
    description text         not null,
    start_date  timestamp    not null,
    end_date    timestamp    not null
);

create table if not exists teams
(
    id             int primary key,
    name           varchar(64) not null,
    competition_id int         not null,
    constraint teams_k1 unique (name, competition_id),
    constraint teams_fk1 foreign key (competition_id) references competitions (id)
);

create table if not exists users
(
    id         int primary key,
    nickname   varchar(32) not null unique,
    email      varchar(32) not null unique,
    first_name varchar(64) not null,
    last_name  varchar(64) not null
);

create table if not exists team_members
(
    team_id int not null,
    user_id int not null,
    constraint team_members_k1 unique (team_id, user_id),
    constraint team_members_fk1 foreign key (team_id) references teams (id),
    constraint team_members_fk2 foreign key (user_id) references users (id)
);

create table if not exists tracks
(
    id             int primary key,
    name           varchar(128) not null,
    description    text         not null,
    competition_id int          not null,
    constraint tracks_k1 unique (name, competition_id),
    constraint tracks_fk1 foreign key (competition_id) references competitions (id)
);

create table if not exists tasks
(
    id          int primary key,
    name        varchar(128) not null,
    description text         not null,
    track_id    int          not null,
    constraint tasks_fk1 foreign key (track_id) references tracks (id)
);


create table if not exists completed_tasks
(
    user_id   int       not null,
    task_id   int       not null,
    timestamp timestamp not null,
    constraint completed_tasks_k1 unique (user_id, task_id),
    constraint completed_tasks_fk1 foreign key (user_id) references users (id),
    constraint completed_tasks_fk2 foreign key (task_id) references tasks (id)
);

create type rank as enum ('bronze', 'silver', 'gold', 'platinum');

-- 'minvalue' is here ONLY for the demonstration purposes, not for production
-- In `insert.sql` I set ids by myself in test example,
-- and in `generate_awards` in `update.sql` procedure it is done by this sequence
CREATE SEQUENCE awards_id_seq minvalue 8;

create table if not exists awards
(
    id             int primary key default nextval('awards_id_seq'),
    name           varchar(128) not null,
    description    text         not null,
    rank           rank         not null,
    tasks_to_gain  int          not null,
    competition_id int          not null,
    constraint awards_k1 unique (name, competition_id),
    constraint awards_fk1 foreign key (competition_id) references competitions (id)
);

ALTER SEQUENCE awards_id_seq
OWNED BY awards.id;

create table if not exists gained_awards
(
    award_id  int       not null,
    user_id   int       not null,
    timestamp timestamp not null,
    place     int       not null,
    constraint gained_awards_pk primary key (award_id, user_id),
    constraint gained_awards_k1 unique (award_id, place),
    constraint gained_awards_fk1 foreign key (award_id) references awards (id),
    constraint gained_awards_fk2 foreign key (user_id) references users (id)
);

-------------
-- Indexes --
-------------

-- Postgres creates indexes for PK and unique constrains automatically, so no need to do it explicitly

-- Queries:
--
-- BestTeams,
-- CompetitionTeamsLeaderboardByTasks,
-- CompetitionTeamsLeaderboardByAwards,
-- TrackTeamsLeaderboard
create index if not exists teams_fk1_index on teams using hash (competition_id);

-- Queries:
--
-- BestTeams,
-- CompetitionTeamsLeaderboardByTasks,
-- CompetitionTeamsLeaderboardByAwards,
-- TrackTeamsLeaderboard
create index if not exists team_members_fk1_index on team_members using hash (team_id);

-- Queries:
--
-- BestTeams,
-- CompetitionTeamsLeaderboardByTasks,
-- CompetitionTeamsLeaderboardByAwards,
-- TrackTeamsLeaderboard
create index if not exists team_members_fk2_index on team_members using hash (user_id);

-- Queries:
--
-- FirstWeekWinners,
-- BestTeams,
-- CompetitionUsersLeaderboardByTasks,
-- CompetitionTeamsLeaderboardByTasks,
-- TrackTeamsLeaderboard,
-- UserCompletedTasks
create index if not exists tracks_fk1_index on tracks using hash (competition_id);

-- Queries:
--
-- FirstWeekWinners,
-- BestTeams,
-- CompetitionUsersLeaderboardByTasks,
-- TrackUsersLeaderboard,
-- CompetitionTeamsLeaderboardByTasks,
-- TrackTeamsLeaderboard,
-- UserCompletedTasks
create index if not exists tasks_fk1_index on tasks using hash (track_id);

-- Queries:
--
-- BestTeams,
-- CompetitionUsersLeaderboardByTasks,
-- TrackUsersLeaderboard,
-- CompetitionTeamsLeaderboardByTasks,
-- TrackTeamsLeaderboard,
-- UserCompletedTasks
create index if not exists completed_tasks_fk1_index on completed_tasks using hash (user_id);

-- Queries:
--
-- FirstWeekWinners,
-- BestTeams,
-- CompetitionUsersLeaderboardByTasks,
-- TrackUsersLeaderboard,
-- CompetitionTeamsLeaderboardByTasks,
-- TrackTeamsLeaderboard,
-- UserCompletedTasks
create index if not exists completed_tasks_fk2_index on completed_tasks using hash (task_id);

-- Queries:
--
-- CompetitionWinners
-- FastestGunInTheWildWest
-- CompetitionUsersLeaderboardByAwards
-- CompetitionTeamsLeaderboardByAwards
-- UserGainedAwards
create index if not exists awards_fk1_index on awards using hash (competition_id);

-- Queries:
--
-- CompetitionWinners
-- FastestGunInTheWildWest
-- CompetitionUsersLeaderboardByAwards
-- CompetitionTeamsLeaderboardByAwards
-- UserGainedAwards
create index if not exists gained_awards_fk1_index on gained_awards using hash (award_id);

-- Queries:
--
-- CompetitionWinners
-- CompetitionUsersLeaderboardByAwards
-- CompetitionTeamsLeaderboardByAwards
-- UserGainedAwards
create index if not exists gained_awards_fk2_index on gained_awards using hash (user_id);
