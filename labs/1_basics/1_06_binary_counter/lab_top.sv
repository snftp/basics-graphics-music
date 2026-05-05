`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
       assign abcdefgh   = '0;
       assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    // Exercise 1: Free running counter.
    // How do you change the speed of LED blinking?
    // Try different bit slices to display.

    localparam w_cnt = $clog2 (clk_mhz * 1000 * 1000);

    /* localparam — это локальная константа модуля.
    В отличие от обычного parameter, её нельзя переопределить извне,
    используется для вычисления внутренних констант, которые зависят
    от других параметров (например, от входной частоты),
    чтобы не вписывать конкретные числа вручную.

    Выражение clk_mhz * 1000 * 1000 переводит частоту из Мегагерц в Герцы.
    Герц (Hz) — это количество тактов (циклов) в одну секунду.
    Если входная частота составляет 50 MHz, то за одну секунду произойдет 50 000 000 тактов.

    Системная функция $clog2 (ceiling log2) вычисляет двоичный логарифм
    с округлением вверх. В цифровой электронике это единственный способ
    определить, сколько бит (физических триггеров) нужно выделить для
    хранения конкретного числа. те w_cnt вычислет разрядность количества тактов */

    logic [w_cnt - 1:0] cnt; // стандартный способ определить диапазон индексов шины

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    /* Бит cnt[ меняет свое состояние (из 0 в 1 или из 1 в 0) каждый такт
    Биты после нулевого меняются благодаря правилам двоичной арифметики.
    Когда младший бит уже равен 1 и к нему прибавляется еще 1,
    происходит перенос разряда в следующий бит.
    Бит cnt[1] меняется в 2 раза реже, чем cnt[0], а cnt[2] — в 4 раза реже */

    assign led = cnt [$left (cnt) -: w_led]; // самый левый слайс cnt то есть самый низкочастотный
    assign led = cnt [$right (cnt) +: w_led]; // самый правый слайс значит самая высокая частота короче ниче не видно
    assign led = cnt [($left (cnt) - 4) -: (w_led - 1)]; // уже различимо глазу и конечно один светодиод не светится

    /* w[x -:y] == w[x:(x-y+1)], $left возвращает индекс страшего бита
    сигнал на led меняется практически мгновенно после обновления cnt.
    Это можно представить как лампочку (led),
    соединенную проводом (assign) с переключателем (cnt)
    Таким образом можно настроить частоту мигания светодиодов */

    //------------------------------------------------------------------------

    // Exercise 2: Key-controlled counter.
    // Comment out the code above.
    // Uncomment and synthesize the code below.
    // Press the key to see the counter incrementing.
    //
    // Change the design, for example:
    //
    // 1. One key is used to increment, another to decrement.
    //
    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.

    wire any_key = | key;

    logic any_key_r;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            any_key_r <= '0;
        else
            any_key_r <= any_key;

    wire any_key_pressed = ~ any_key & any_key_r;

    logic [w_led - 1:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (any_key_pressed)
            cnt <= cnt + 1'd1;

    assign led = w_led' (cnt);


    // 1. One key is used to increment, another to decrement.

    wire inc_key = |key[0];
    wire dec_key = |key[1];

    logic inc_key_r, dec_key_r;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            inc_key_r <= '0;
            dec_key_r <= '0;
        end
        else
        begin
            inc_key_r <= inc_key;
            dec_key_r <= dec_key;
        end

    wire inc_key_pressed = ~ inc_key & inc_key_r;
    wire dec_key_pressed = ~ dec_key & dec_key_r;

    logic [w_led - 1:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else if (inc_key_pressed)
            cnt <= cnt + 1'd1;
        else if (dec_key_pressed)
            cnt <= cnt - 1'd1;

    assign led = w_led' (cnt);

    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.

    wire key_0 = |key[0];
    wire key_1 = |key[1];

    logic key_0_r, key_1_r;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            key_0_r <= '0;
            key_1_r <= '0;
        end
        else
        begin
            key_0_r <= key_0;
            key_1_r <= key_1;
        end

    wire key_0_pressed = ~ key_0 & key_0_r;
    wire key_1_pressed = ~ key_1 & key_1_r;

    logic [1:0] cnt0;
    logic [1:0] cnt1;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            cnt0 <= '0;
            cnt1 <= '0;
        end
        else if (key_0_pressed)
            cnt0 <= cnt0 + 1'd1;
        else if (key_1_pressed)
            cnt1 <= cnt1 + 1'd1;

    assign led = w_led' ({cnt1, cnt0});



endmodule
