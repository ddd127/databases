# 2. Архитектура современной СУБД

Программа

  ↓ 
  
Драйвер

  ↓ 
  
*Сеть* 

  ↓ 
  
Драйвер

  ↓ 
  
CУБД *(попали на ту же машинку что и данные)*

  ↓  
  
Разборщик запроса

*Парсит sql на внутренний язык бд*

 ↓  
 
 Построение плана исполнения

 *Строит эффективный план, обращается к хранилищу данных, смотрит статистику*
 Исполнитель запроса
 
  ↓  
  
  Управление памятью

  *кэш, число свободной памяти, хватит ли на запрос*
  
  ↓ 
  
  Хранилище данных
  
  
  **Схема:**
  https://www.kgeorgiy.info/courses/dbms/slides/intro.xhtml#(53)
  
  Стрелки означают кто кого использует
