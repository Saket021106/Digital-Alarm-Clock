# Digital Alarm Clock — RTL Design (SystemVerilog)

A hierarchical, RTL-level digital alarm clock implemented in SystemVerilog. The design tracks a 24-hour current time, allows a user to program both the current time and an alarm time through a shared numeric keypad, and drives a 4-digit seven-segment-style display along with an alarm sound output.



https://github.com/user-attachments/assets/844c72ae-f6a0-4905-9b4e-b0ae39913a86



## Repository Structure

| File | Description |
|---|---|
| `README.md` | This file. |
| `RTL SCHEMATIC.png` | Block-level schematic of the synthesized design showing module connectivity. |
| `design.sv` | Top-level source containing the full module hierarchy (also mirrored in `alarm_clk_rtl.sv`). |
| `alarm_clk_rtl.sv` | Top module `alarm_clk_rtl` instantiating and wiring together every sub-block. |
| `aclk_timegen.sv` | Free-running counter that derives the one-second and one-minute tick pulses. |
| `aclk_controller.sv` | Finite state machine that governs mode switching, key entry, and control signal generation. |
| `aclk_keyreg.sv` | Shift register that buffers the four most recently entered keypad digits. |
| `aclk_areg.sv` | Storage register for the programmed alarm time. |
| `aclk_counter.sv` | Storage/counter register for the current time, with BCD-style rollover logic. |
| `display_driver.sv` | Per-digit display driver logic (instantiated four times to cover HH:MM). |
| `testbench.sv` | Simulation testbench used to exercise and verify `alarm_clk_rtl`. |
| `hvsync_generator.v` | VGA horizontal/vertical sync generator, used only for the 8bitworkshop visualization below. |
| `test_hvsync.v` | Demo top module that renders a seven-segment clock on a VGA display via 8bitworkshop. Built on a similar counting concept to `design.sv`, but is a separate, simplified implementation intended purely to show the idea running on an actual display. |

## Architecture Overview

The design is split into single-responsibility blocks connected by a small set of control signals generated entirely by the controller FSM. This keeps the datapath (counters/registers) free of decision logic and keeps the FSM free of arithmetic.

<img width="1544" height="926" alt="RTL SCHEMATIC" src="https://github.com/user-attachments/assets/19589922-5dd7-4362-8392-32587120046f" />


At the top level, `alarm_clk_rtl` instantiates:

- `aclk_timegen` — timing reference generator
- `aclk_controller` — control FSM
- `aclk_keyreg` — keypad entry buffer
- `aclk_counter` — current-time register
- `aclk_areg` — alarm-time register
- `aclk_lcd_display` — display formatting and alarm comparison (built from four `aclk_lcd_driver` instances)

## Module Descriptions

### `aclk_timegen` — Time Base Generator

Generates the two timing pulses that drive the rest of the system from a single free-running 14-bit counter.

- `count` increments every clock edge and wraps back to `0` at `15359` (i.e. a full cycle is `15360` clock periods).
- `reset_count`, driven by the controller, allows the counter to be re-synchronized whenever the user commits a new current time.
- `one_second` is asserted whenever the lower 8 bits of `count` reach `8'hFF`, i.e. once every 256 clock periods.
- `one_minute` is asserted once per full 15360-cycle period (60 seconds worth of `one_second` pulses), **unless** `fast_watch` is asserted, in which case `one_minute` is tied directly to `one_second`. This lets the clock be sped up (one simulated "minute" per real second) for fast testing/demo purposes without changing any other module.

### `aclk_controller` — Control FSM

A Moore-type finite state machine with seven states that governs how key presses are interpreted and which register gets updated.

| State | Purpose |
|---|---|
| `SHOW_TIME` | Idle/default state, current time is displayed. |
| `SHOW_ALARM` | Alarm button held down; alarm time is displayed instead of current time. |
| `KEY_STORED` | A key press has just been shifted into the key buffer. |
| `KEY_WAITED` | Waiting for either the next key press or a timeout. |
| `KEY_ENTRY` | A new key press has arrived while waiting; checks whether the user is committing to set the alarm or current time. |
| `SET_ALARM_TIME` | Commits the 4-digit key buffer into the alarm register. |
| `SET_CURRENT_TIME` | Commits the 4-digit key buffer into the current-time register and resynchronizes the time base. |

Key behavioral notes:

- `key == 4'd10` is used as a sentinel meaning "no key currently pressed." Any other 4-bit value (`0`–`9`) is treated as a valid keypad digit.
- A 4-bit `timeout_cnt`, incremented once per `one_second` while in `KEY_ENTRY` or `KEY_WAITED`, implements a 10-second key-entry timeout (`timeout = timeout_cnt >= 10`). If the user stops entering digits for 10 seconds, the FSM falls back to `SHOW_TIME`.
- Pressing `alarm_button` or `time_button` while in `KEY_ENTRY` commits the currently buffered digits as the new alarm time or current time, respectively.
- All outputs (`reset_count`, `load_new_c`, `load_new_a`, `show_a`, `show_new_time`, `shift`) are pure functions of the current state only (Moore outputs), which keeps them glitch-free with respect to inputs changing mid-cycle.

### `aclk_keyreg` — Key Entry Buffer

A 4-stage shift register that captures the last four digits typed on the keypad, most-significant digit first.

- On every pulse of `shift` (asserted by the controller in `KEY_STORED`), the buffer shifts: `ls_min → ms_min`, `ms_min → ls_hr`... effectively `ls_hr → ms_hr`, `ms_min → ls_hr`, `ls_min → ms_min`, and the new `key` value enters at `ls_min`.
- This buffer feeds both `aclk_counter` and `aclk_areg` as the "new time" source when the user commits an entry, so the same four typed digits can become either the new current time or the new alarm time depending on which button is pressed.

### `aclk_areg` — Alarm Time Register

Simple loadable register holding the four BCD digits of the alarm time (`ms_hr`, `ls_hr`, `ms_min`, `ls_min`). It loads from the key buffer whenever `load_new_a` is asserted (i.e. while in `SET_ALARM_TIME`), and otherwise holds its value.

### `aclk_counter` — Current Time Register

Holds the four BCD digits of the current time and implements 24-hour rollover arithmetic:

- If `load_new_c` is asserted, the register is loaded directly from the key buffer (user-set time), bypassing the normal increment logic.
- Otherwise, on every `one_minute` pulse, the counter increments using cascaded BCD rollover:
  - `23:59 → 00:00` (checked explicitly against `ms_hr=2, ls_hr=3, ms_min=5, ls_min=9`)
  - `ls_hr` rolls from `9` to `0` and `ms_hr` increments when minutes reach `:59`
  - `ls_min` rolls from `9` to `0` and `ms_min` increments when the ones-of-minutes reach `9`
  - otherwise `ls_min` simply increments

This gives a standard 24-hour HH:MM display with correct hour/minute carry behavior.

### `aclk_lcd_driver` — Single Digit Display Mux

A per-digit combinational block used four times (once per displayed digit — MS hour, LS hour, MS minute, LS minute).

- Selects which value to show based on the controller's mode flags:
  - `show_a && !show_new_time` → show the corresponding alarm-time digit
  - `!show_a && show_new_time` → show the corresponding key-buffer digit (live key entry feedback)
  - otherwise → show the corresponding current-time digit
- Converts the selected 4-bit BCD digit into an 8-bit ASCII character by adding `0x30` (ASCII `'0'`), producing `display_time`.
- Also computes a per-digit `sound_alarm` flag, asserted when this digit's current-time value equals its alarm-time value.

### `aclk_lcd_display` — Four-Digit Display Assembly

Instantiates four `aclk_lcd_driver` blocks (`u_ms_hr`, `u_ls_hr`, `u_ms_min`, `u_ls_min`) to drive all four displayed digits in parallel, and combines their individual alarm-match flags with a logical AND. The alarm therefore only sounds when **all four digits** of the current time simultaneously match all four digits of the programmed alarm time.

### `alarm_clk_rtl` — Top-Level Integration

Wires every block above together:

1. `aclk_timegen` produces `one_second` / `one_minute` from the free-running clock.
2. `aclk_controller` consumes `one_second`, `alarm_button`, `time_button`, and `key`, and produces every control signal used elsewhere in the design.
3. `aclk_keyreg` captures typed digits under control of `shift`.
4. `aclk_counter` and `aclk_areg` hold current time and alarm time respectively, loaded from the key buffer under control of `load_new_c` / `load_new_a`.
5. `aclk_lcd_display` selects and formats what should currently be shown (current time, alarm time, or live key entry) and evaluates whether the alarm should sound.

## Simulation and Verification

`testbench.sv` instantiates `alarm_clk_rtl` and drives its inputs (clock, reset, button presses, and keypad codes) to exercise time counting, key entry, alarm programming, and the alarm trigger condition. `display_driver.sv` supports the testbench/simulation side by handling per-digit display logic used for verification.

## 8bitworkshop VGA Demo (`hvsync_generator.v`, `test_hvsync.v`)

These two files are **not** the same design as `design.sv` / `alarm_clk_rtl`. They implement a separate, simplified clock built on the same general "count seconds/minutes/hours and render digits" concept, but targeted at the [8bitworkshop](https://8bitworkshop.com/) online Verilog simulator so the clock can actually be *seen* running on a simulated VGA display with seven-segment-style digits:

- `hvsync_generator.v` produces standard VGA horizontal and vertical sync timing along with pixel coordinates.
- `test_hvsync.v` uses that timing to rasterize a seven-segment digit clock onto the VGA frame.

This pair of files exists purely as a visual demonstration and is independent of the RTL alarm clock design documented above.
