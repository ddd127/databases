insert into users(user_id, login, name, surname)
values (1, 'loc_admin1', 'Администратор 1', 'Локализации'),
       (2, 'loc_admin2', 'Администратор 2', 'Локализации'),
       (3, 'translator1', 'Переводчик', 'На контракте'),
       (4, 'translator2', 'Переводчик', 'Аутсорс'),
       (5, 'manager', 'Менеджер', 'Всея Яндекса'),
       (6, 'search_developer', 'Разработчик', 'Яндекс.Поиск'),
       (7, 'taxi_developer', 'Разработчик', 'Яндекс.Такси'),
       (8, 'lavka_developer', 'Разработчик', 'Яндекс.Лавка'),
       (9, 'robot-ci', 'Робот', 'Для авторизации в CI процессах');

insert into teams(team_id, code, name)
values (1, 'loc_admins', 'Администраторы сервисов локализации'),
       (2, 'inner_translators', 'Штатные переводчики'),
       (3, 'outsource_translators', 'Внешние переводчики'),
       (4, 'managers', 'Менеджеры'),
       (5, 'developers', 'Все разработчики'),
       (6, 'search_developers', 'Разработчики Поиска'),
       (7, 'go_developers', 'Разработчики Яндекс.Go'),
       (8, 'taxi_developers', 'Разработчики Яндекс.Такси'),
       (9, 'lavka_developers', 'Разработчики Яндекс.Лавки'),
       (10, 'robots', 'Роботы');

insert into team_members(team_id, user_id)
values (1, 1),
       (1, 2),

       (2, 3),
       (3, 4),

       (4, 5),

       (5, 6),
       (5, 7),
       (5, 8),

       (6, 6),

       (7, 7),
       (7, 8),
       (8, 7),
       (9, 8),

       (10, 9);

-- Интерфейсным ключом называется множество текстов, состоящее из оригинального текста и переводов
-- Например, всевозможные переводы кнопки "Купить" - это один интерфейсный ключ
insert into services(service_id, code, name, owner_id)
values (1, 'translation_memory', 'Память переводов', 4),
       (2, 'interface_keys', 'Интерфейсные ключи', 3);

insert into actions(service_id, code, name)
values (1, 'read', 'Просмотреть память переводов'),
       (1, 'write', 'Отредактировать память переводов'),

       (2, 'change_source', 'Поменять исходный текст'),
       (2, 'change_target', 'Поменять текст перевода'),
       (2, 'download_keys', 'Выгрузить ключи');

insert into section_codes(code_id, code)
values (1, 'common'),
       (2, 'search'),
       (3, 'go'),
       (4, 'lavka'),
       (5, 'taxi');

insert into sections(service_id, code_id, name)
values (1, 1, 'Общая память переводов'),

       (2, 1, 'Пересекающиеся ключи'),
       (2, 2, 'Ключи Поиска'),
       (2, 3, 'Ключи Go'),
       (2, 4, 'Ключи Такси'),
       (2, 5, 'Ключи Лавки');

insert into section_parents(service_id, section_code_id, parent_code_id)
values (2, 4, 3),
       (2, 5, 3); -- Лавка и Такси - подразделения внутри Go

insert into roles(team_id, service_id, section_code_id, action_code, granted_by, expiration_ts)
-- администраторы локализации могут смотреть и менять память переводов.
values (1, 1, 1, 'read', 1, null),
       (1, 1, 1, 'write', 1, null),

       -- штатные переводчики имеют доступ к памяти переводов.
       (2, 1, 1, 'read', 2, null),

       -- штатные переводчики умеют переводить всё.
       (2, 2, 2, 'change_target', 5, null),
       (2, 2, 3, 'change_target', 5, null),

       -- все разработчики имеют доступ к общим ключам
       (5, 2, 1, 'change_source', 5, null),

       -- разработчики имеют доступ к ключам своего сервиса
       (6, 2, 2, 'change_source', 5, null),
       (7, 2, 3, 'change_source', 5, null),
       (8, 2, 4, 'change_source', 5, null),
       (9, 2, 5, 'change_source', 5, null),

       -- В Go авторизуют CI роботом - ему нужно уметь выгружать тексты.
       (10, 2, 2, 'download_keys', 5, null),

       -- В такси завал, нужна помощь разработчиков из лавки
       -- выдадим им временный доступ до ключей такси, пусть фичи делают.
       (9, 2, 4, 'change_source', 5, '2023-04-01'),

       -- стало больше фич - надо больше переводить.
       -- привлекаем внештатных переводчиков к переводу ключей такси.
       (3, 2, 4, 'change_target', 5, '2023-04-01');
