insert into competitions (id, name, description, start_date, end_date)
values (1, 'Summer event', '2023 online Summer competition', '2023-06-01 12:00:00', '2023-08-31 12:00:00'),
       (2, 'Winter event', '2023-2024 online Winter competition', '2023-12-01 12:00:00', '2024-02-28 12:00:00');

insert into teams (id, name, competition_id)
values (1, 'Summer Team 1', 1),
       (2, 'Summer Team 2', 1),
       (3, 'Summer Team 3', 1),
       (4, 'Summer Team 4', 1),
       (5, 'Winter Team 1', 2),
       (6, 'Winter Team 2', 2),
       (7, 'Winter Team 3', 2);

insert into users (id, nickname, email, first_name, last_name)
values (1, 'tony_1', 'tony1@email.com', 'Tony', 'Stark'),
       (2, 'jane_2', 'jane2@email.com', 'Jane', 'Foster'),
       (3, 'tor_3', 'tor3@email.com', 'Tor', 'Odin-son'),
       (4, 'loki_4', 'loki4@email.com', 'Loki', 'Odin-son'),
       (5, 'nat_5', 'nat5@email.com', 'Natasha', 'Romanov'),
       (6, 'cap_6', 'cap6@email.com', 'Steve', 'Rodgers'),
       (7, 'hulk_7', 'hulk7@email.com', 'Bruce', 'Banner'),
       (8, 'hawk_8', 'hawk8@email.com', 'Clint', 'Barton'),
       (9, 'nick_9', 'nick9@email.com', 'Nick', 'Fury'),
       (10, 'tanos_10', 'tanos10@email.com', 'Tanos', 'Kazahstanos');

-- разбиение на команды
insert into team_members (team_id, user_id)
values (1, 1),
       (1, 2);

insert into team_members (team_id, user_id)
values (2, 3),
       (2, 4),
       (2, 5);

insert into team_members (team_id, user_id)
values (3, 1),
       (3, 6),
       (3, 7);

insert into team_members (team_id, user_id)
values (4, 3),
       (4, 4),
       (4, 10);

insert into team_members (team_id, user_id)
values (5, 1),
       (5, 2),
       (5, 5);

insert into team_members (team_id, user_id)
values (6, 6),
       (6, 7),
       (6, 10);


insert into tracks (id, name, description, competition_id)
values (1, 'summer sport', 'summer sport challenge', 1),
       (2, 'summer films', 'summer films challenge', 1),
       (3, 'winter sport', 'summer sport challenge', 2);

insert into tasks (id, name, description, track_id)
values (1, 'push-ups', 'do push-ups', 1),
       (2, 'football', 'play football', 1),
       (3, 'yoga', 'do morning yoga', 1),
       (4, 'run', 'run 3 km', 1),
       (5, 'avengers', 'watch avengers', 2),
       (6, 'iron man', 'watch iron man', 2),
       (7, 'thor 3', 'watch thor 3', 2),
       (8, 'push-ups', 'do push-ups', 3),
       (9, 'ski', 'go skiing', 3),
       (10, 'pool', 'swim in a lake', 3);

-- участник 1 выполнил 7 заданий в соревновании 1
-- остальные данные для статистики
insert into completed_tasks (task_id, user_id, timestamp)
values (1, 1, '2023-06-01 12:00:00'),
       (2, 1, '2023-06-02 12:00:00'),
       (3, 1, '2023-06-02 12:00:00'),
       (4, 1, '2023-06-02 12:00:00'),
       (5, 1, '2023-06-02 12:00:00'),
       (6, 1, '2023-06-10 12:00:00'),
       (7, 1, '2023-06-02 12:00:00'),

       (1, 2, '2023-06-02 12:00:00'),
       (2, 3, '2023-06-03 12:00:00'),
       (2, 4, '2023-06-04 12:00:00'),
       (3, 5, '2023-06-05 12:00:00'),
       (4, 6, '2023-06-06 12:00:00'),
       (4, 7, '2023-06-07 12:00:00'),
       (4, 8, '2023-06-08 12:00:00'),
       (5, 9, '2023-06-09 12:00:00'),
       (6, 2, '2023-06-12 12:00:00'),
       (6, 3, '2023-06-12 12:00:00'),
       (7, 4, '2023-06-12 12:00:00'),
       (9, 5, '2023-12-01 12:00:00'),
       (9, 6, '2023-12-02 12:00:00'),
       (10, 1, '2023-12-03 12:00:00');


insert into awards (id, name, description, rank, tasks_to_gain, competition_id)
values (1, 'good start', 'complete 1 task', 'bronze', 1, 1),
       (2, 'half way', 'complete 3 tasks', 'silver', 3, 1),
       (3, 'almost there', 'complete 6 tasks', 'gold', 6, 1),
       (4, 'king of the world', 'complete 7 tasks', 'platinum', 7, 1),
       (5, 'good start', 'complete 1 task', 'bronze', 1, 2),
       (6, 'half way', 'complete 2 tasks', 'silver', 2, 2),
       (7, 'king of the world', 'complete 3 tasks', 'gold', 3, 2);

-- участник 1 выполнил 7 заданий в соревновании 1 и получил все награды
-- остальные получили по одной
insert into gained_awards (award_id, user_id, timestamp, place)
values (1, 1, '2023-06-01 12:00:00', 1),
       (2, 1, '2023-06-02 12:00:00', 1),
       (3, 1, '2023-06-02 12:00:00', 1),
       (4, 1, '2023-06-10 12:00:00', 1),
       (1, 2, '2023-06-02 12:00:00', 2),
       (1, 3, '2023-06-03 12:00:00', 3),
       (1, 4, '2023-06-04 12:00:00', 4),
       (1, 5, '2023-06-05 12:00:00', 5),
       (1, 6, '2023-06-06 12:00:00', 6),
       (1, 7, '2023-06-07 12:00:00', 7),
       (1, 8, '2023-06-08 12:00:00', 8),
       (1, 9, '2023-06-09 12:00:00', 9),
       (5, 5, '2023-12-01 12:00:00', 1),
       (5, 6, '2023-12-02 12:00:00', 2),
       (5, 1, '2023-12-03 12:00:00', 3);
