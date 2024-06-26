## 24. Подсистема хранения данных

### Модули системы хранения

- **Диспетчер записей**

  Отвечает за доступ к конкретным записям, запрошенным СУБД

  - Знает, на каких страницах располагаются нужные записи
  - Умеет запрашивать эти страницы у диспетчера страниц
  - Умеет извлекать из полученных страниц нужную информацию


- **Диспетчер страниц**

  Отвечает за подгрузку конкретных страниц в оперативную память

  - запрашивает диапазоны страниц у диспетчера диска
  - заведует загрузкой/выгрузкой кеша страниц
  - минимизирует обращения к диску


- **Диспетчер диска**

  Отвечает за подгрузку диапазонов страниц с диска

  - знает, где и как на диске лежат определенные страницы
  - перегруппировывает запросы страниц
  - пытается сделать чтение с диска последовательным


### Организация данных на диске

Может быть поверх сырого раздела диска, 
может быть поверх файловой системы. 
Если поверх файловой системы, то так:

- Файл - одна (или несколько) таблиц
- Таблица - несколько страниц
- Страница - несколько записей

Если запись больше, чем страница, все становится очень плохо. 
Некоторые субд отказываются иметь записи, не влезающие на страницу. 
Исключение - blob и clob, которые хранятся отдельно 
и не участвуют в логической части запроса
(их можно только загрузить и выгрузить, 
нельзя проанализировать в рамках запроса).

### Список страниц

**Заголовок страницы:**

- Id
- Id предыдущей страницы
- Id следующей страницы
- Тип хранимых данных (напр: "записи такой-то таблицы")

Список страниц - это двусвязный список

В теле страницы хранятся либо записи, 
либо другая информация соответствующего типа

Id записи состоит из Id страницы и положения записи внутри страницы
Таким образом, по Id записи, откинув младшие биты, 
можно получить Id страницы

Id записи иммутабелен, число записей на странице ограничено

**Тело страницы:**

В теле страницы с одной стороны пишутся, собственно, записи, 
а с другой - каталог этих записей, 
чтобы можно было быстро найти на странице запись с конкретным Id.

**А если страница переполнилась при изменении записи?**

Тогда:
- аллоцируем новую страницу - "страницу переполнения"
- запишем туда то, что не влезало (и мб еще какие-то записи)
- туда, где были перенесенные записи, впишем ссылку на их новое место

В случае, если переполнилась страница переполнения, 
поделим её на две и обновим ссылки на оригинальной странице

**Сжатие данных**

Данные на страницах можно сжимать.

Например, если на одну страницу попали отсортированные строки или набор id, 
то, скорее всего, у строк есть общий префикс, а id не сильно отличаются, 
следовательно, можно вынести общие части строк или id, 
скорее всего, сильно уменьшив занимаемое место

Такое сжатие умешьшает число io операций, 
а дополнительные затраты на работу процессора 
в таком случае пренебрежимо малы
