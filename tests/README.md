# FPGA Clock Project Testbenches

Этот каталог содержит comprehensive testbenches для всех модулей проекта FPGA часов.

## Структура тестов

### Модульные тесты
- `button_debounce_tb.v` - Тест модуля debounce кнопок
- `counter_tb.v` - Тест универсального счетчика
- `clock_master_tb.v` - Тест генератора тактовых сигналов
- `display_tb.v` - Тест модуля отображения 7-сегментного дисплея
- `control_unit_tb.v` - Тест блока управления состоянием
- `clock_counters_tb.v` - Тест счетчиков времени (секунды, минуты, часы)
- `clock_top_tb.v` - Тест верхнего уровня системы

### Интеграционные тесты
- `integration_test.v` - Полный интеграционный тест всей системы

## Запуск тестов

### Все тесты
```bash
make test-all
```

### Отдельные тесты
```bash
make test-button       # Тест debounce кнопок
make test-counter      # Тест счетчика
make test-clock-master # Тест генератора тактов
make test-display      # Тест дисплея
make test-control      # Тест блока управления
make test-counters     # Тест счетчиков времени
make test-top          # Тест верхнего уровня
make test-integration  # Интеграционный тест
```

### Тесты с генерацией VCD файлов
```bash
make wave-all          # Все тесты с VCD
make wave-button       # Конкретный тест с VCD
# и т.д.
```

## Описание тестов

### button_debounce_tb.v
- Тестирует фильтрацию дребезга кнопок
- Проверяет нормальную работу, шумные входы, короткие нажатия
- Включает тесты множественных нажатий и длительных удержаний

### counter_tb.v
- Тестирует универсальный счетчик с параметрами
- Проверяет сброс, подсчет, переполнение, перенос
- Тестирует включение/выключение подсчета

### clock_master_tb.v
- Тестирует генератор тактовых сигналов
- Проверяет частоты: 1024Hz, 512Hz, 2Hz, 1Hz
- Тестирует импульс Enable_Clock_1Hz

### display_tb.v
- Тестирует 7-сегментный дисплей
- Проверяет мультиплексирование, точки, все цифры 0-9
- Тестирует неверные значения и граничные случаи

### control_unit_tb.v
- Тестирует конечный автомат управления
- Проверяет переходы между состояниями: IDLE, RESET_SEC, SET_MIN, SET_HOUR
- Тестирует все комбинации входных сигналов

### clock_counters_tb.v
- Тестирует счетчики времени
- Проверяет подсчет секунд, минут, часов
- Тестирует переполнения и сбросы
- Проверяет ручной режим инкремента

### clock_top_tb.v
- Тестирует верхний уровень системы
- Проверяет работу кнопок Set и Up
- Тестирует режимы настройки времени
- Проверяет debouncing и мультиплексирование

### integration_test.v
- Полный интеграционный тест всей системы
- Тестирует взаимодействие всех модулей
- Проверяет длительную работу
- Тестирует все пользовательские сценарии

## Требования

- Icarus Verilog (iverilog)
- GTKWave (для просмотра VCD файлов)
- Make

## Установка зависимостей

### Ubuntu/Debian
```bash
sudo apt-get install iverilog gtkwave
```

### macOS
```bash
brew install icarus-verilog gtkwave
```

### Windows
Скачайте с официальных сайтов:
- [Icarus Verilog](http://iverilog.icarus.com/)
- [GTKWave](http://gtkwave.sourceforge.net/)

## Запуск

1. Перейдите в корневую директорию проекта
2. Запустите все тесты: `make test-all`
3. Для просмотра waveforms: `make wave-integration`

## Результаты тестов

Каждый тест выводит:
- Количество выполненных тестов
- Количество ошибок
- Статус PASS/FAIL для каждого теста
- Общий результат

## Отладка

Для отладки используйте VCD файлы:
```bash
make wave-integration
```
Это откроет GTKWave с полной временной диаграммой системы.

## Структура проекта

```
clock_on_fpga/
├── rtl/                    # Исходный код RTL
│   ├── button_debounce.v
│   ├── counter.v
│   ├── clock_master.v
│   ├── display.v
│   ├── control_unit.v
│   ├── clock_counters.v
│   └── clock_top.v
├── tests/                  # Тесты
│   ├── button_debounce_tb.v
│   ├── counter_tb.v
│   ├── clock_master_tb.v
│   ├── display_tb.v
│   ├── control_unit_tb.v
│   ├── clock_counters_tb.v
│   ├── clock_top_tb.v
│   ├── integration_test.v
│   └── README.md
├── Makefile               # Сборочный файл
└── README.md             # Основной README
```
