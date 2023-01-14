insert into teams (team_id, code, name)
values (0, 'test', 'test');


insert into services(service_id, code, name, owner_id)
values (0, 'test', 'test', 0);

insert into section_codes(code_id, code)
values (1, 'a'),
       (2, 'b'),
       (3, 'c'),
       (4, 'd'),
       (5, 'e');

insert into sections (service_id, code_id, name)
values (0, 1, 'a'),
       (0, 2, 'b'),
       (0, 3, 'c'),
       (0, 4, 'd'),
       (0, 5, 'e');



insert into section_parents(service_id, section_code_id, parent_code_id)
values (0, 2, 1);

select * from section_root_path;



insert into section_parents(service_id, section_code_id, parent_code_id)
values (0, 3, 2);

select * from section_root_path;



insert into section_parents(service_id, section_code_id, parent_code_id)
values (0, 4, 3);

select * from section_root_path;



insert into section_parents(service_id, section_code_id, parent_code_id)
values (0, 5, 3);

select * from section_root_path;



update section_parents
set parent_code_id = 1
where service_id = 0 and section_code_id = 3;

select * from section_root_path;


delete
from section_parents
where service_id = 0 and section_code_id = 3;


select * from section_root_path;
