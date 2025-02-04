package aoc

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:unicode"

main :: proc() {
	// track for memory leaks
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	day4()
}

day1 :: proc() {
	data: []u8 = #load("../inputs/day1.txt")

	assert(len(data) > 0)

	left, right: [dynamic]string
	total_distance := 0
	sim_score := 0
	line_done := false

	for char, index in data {
		if char == ' ' {
			if line_done do continue

			append(&left, string(data[index - 5:index]))
			append(&right, string(data[index + 3:index + 8]))
			line_done = true
		}

		if char == '\n' do line_done = false
	}

	assert(len(left) == len(right))

	slice.sort(left[:])
	slice.sort(right[:])

	for i := 0; i < len(left); i += 1 {
		line_sim_score := 0
		left_n := strconv.atoi(left[i])
		right_n := strconv.atoi(right[i])

		if right_n > left_n do total_distance += right_n - left_n
		else do total_distance += left_n - right_n

		for j := 0; j < len(right); j += 1 {
			right_n_2 := strconv.atoi(right[j])
			if left_n == right_n_2 do line_sim_score += 1
		}

		sim_score += left_n * line_sim_score
	}

	fmt.println(total_distance, sim_score)
}

day2 :: proc() {
	data: []u8 = #load("../inputs/day2.txt")

	assert(len(data) > 0)

	safe_count := 0
	numbers: [dynamic]int
	curr_num: [dynamic]u8

	for char in data {
		if char == ' ' {
			append(&numbers, strconv.atoi(string(curr_num[:])))
			clear(&curr_num)
		} else if char == '\n' {
			is_good_report :: proc(numbers: []int) -> bool {
				is_line_valid := false

				asc_cb :: proc(i, j: int) -> bool {
					if i < j do return true
					else do return false
				}

				desc_cb :: proc(i, j: int) -> bool {
					if i > j do return true
					else do return false
				}

				asc := slice.is_sorted_by(numbers, asc_cb)
				desc := slice.is_sorted_by(numbers, desc_cb)

				for i := 0; i < len(numbers) - 1; i += 1 {
					max_n := max(numbers[i + 1], numbers[i])
					min_n := min(numbers[i + 1], numbers[i])
					gap := max_n - min_n

					if gap > 0 && gap < 4 do is_line_valid = true
					else {
						is_line_valid = false
						break
					}
				}

				return (asc ~ desc) && is_line_valid
			}

			append(&numbers, strconv.atoi(string(curr_num[:])))

			if is_good_report(numbers[:]) do safe_count += 1
			else {
				for _, idx in numbers {
					old_val := numbers[idx]
					ordered_remove(&numbers, idx)

					if is_good_report(numbers[:]) {
						safe_count += 1
						break
					} else do inject_at(&numbers, idx, old_val)
				}
			}

			clear(&curr_num)
			clear(&numbers)
		} else {
			append(&curr_num, char)
		}
	}
	fmt.println(safe_count)
}

day3 :: proc() {
	data: []u8 = #load("../inputs/day3.txt")
	assert(len(data) > 0)

	pattern_is_matching := false
	comma_encountered := false
	mul_enable := true
	total_score: u64 = 0
	total_instr := 0

	n1 := 0
	n2 := 0
	n1_str: [dynamic]u8
	n2_str: [dynamic]u8

	for index := 0; index < len(data) - 10; {
		char := data[index]

		if !pattern_is_matching {
			if string(data[index:index + 4]) == "mul(" && mul_enable {
				pattern_is_matching = true
				index += 4
				continue
			} else if string(data[index:index + 4]) == "do()" {
				mul_enable = true
			} else if string(data[index:index + 7]) == "don't()" {
				mul_enable = false
			}
		} else if unicode.is_number(rune(char)) && pattern_is_matching {
			if comma_encountered {
				append(&n2_str, data[index])
			} else {
				append(&n1_str, data[index])
			}
		} else if char == ',' && pattern_is_matching {
			comma_encountered = true
		} else if char == ')' && pattern_is_matching {
			n1 = strconv.atoi(string(n1_str[:]))
			n2 = strconv.atoi(string(n2_str[:]))

			total_score += u64(n1 * n2)
			total_instr += 1

			comma_encountered = false
			pattern_is_matching = false
			n1 = 0
			n2 = 0

			clear(&n1_str)
			clear(&n2_str)
		} else {
			pattern_is_matching = false
			comma_encountered = false
			n1 = 0
			n2 = 0

			clear(&n1_str)
			clear(&n2_str)
		}
		index += 1
	}
	fmt.println(total_score, total_instr)
}

day4 :: proc() {
	data: []u8 = #load("../inputs/day4.txt")
	assert(len(data) > 0)

	COLS :: 140
	ROWS :: 140
	ws: [COLS][ROWS]rune
	score := 0
	line_i := 0

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		for char, char_i in line {
			ws[line_i][char_i] = char
		}
		line_i += 1
	}

	for x := 0; x < COLS - 3; x += 1 {
		for y := 0; y < ROWS - 3; y += 1 {
			// horizontal
			if x + 3 < COLS {
				if ws[x][y] == 'X' &&
				   ws[x + 1][y] == 'M' &&
				   ws[x + 2][y] == 'A' &&
				   ws[x + 3][y] == 'S' {
					score += 1
				}
			}
			if x - 3 > 0 {
				if ws[x][y] == 'X' &&
				   ws[x - 1][y] == 'M' &&
				   ws[x - 2][y] == 'A' &&
				   ws[x - 3][y] == 'S' {
					score += 1
				}
			}

			// vertical
			if y + 3 < ROWS {
				if ws[x][y] == 'X' &&
				   ws[x][y + 1] == 'M' &&
				   ws[x][y + 2] == 'A' &&
				   ws[x][y + 3] == 'S' {
					score += 1
				}
			}
			if y - 3 > 0 {
				if ws[x][y] == 'X' &&
				   ws[x][y + 1] == 'M' &&
				   ws[x][y + 2] == 'A' &&
				   ws[x][y + 3] == 'S' {
					score += 1
				}
			}

			// diagonal
			// sud est
			if x + 3 < COLS && y + 3 < ROWS {
				if ws[x][y] == 'X' &&
				   ws[x + 1][y + 1] == 'M' &&
				   ws[x + 2][y + 2] == 'A' &&
				   ws[x + 3][y + 3] == 'S' {
					score += 1
				}
				// if ws[x][y] == 'S' &&
				//    ws[x + 1][y + 1] == 'A' &&
				//    ws[x + 2][y + 2] == 'M' &&
				//    ws[x + 3][y + 3] == 'X' {
				// 	score += 1
				// }
			}

			// nord est
			if y - 3 >= 0 && x + 3 < COLS {
				if ws[x][y] == 'X' &&
				   ws[x + 1][y - 1] == 'M' &&
				   ws[x + 2][y - 2] == 'A' &&
				   ws[x + 3][y - 3] == 'S' {
					score += 1
				}
				// if ws[x][y] == 'S' &&
				//    ws[x + 1][y - 1] == 'A' &&
				//    ws[x + 2][y - 2] == 'M' &&
				//    ws[x + 3][y - 3] == 'X' {
				// 	score += 1
				// }
			}

			// nord ouest
			if y - 3 >= 0 && x - 3 > 0 {
				if ws[x][y] == 'X' &&
				   ws[x - 1][y - 1] == 'M' &&
				   ws[x - 2][y - 2] == 'A' &&
				   ws[x - 3][y - 3] == 'S' {
					score += 1
				}
				// if ws[x][y] == 'S' &&
				//    ws[x - 1][y - 1] == 'A' &&
				//    ws[x - 2][y - 2] == 'M' &&
				//    ws[x - 3][y - 3] == 'X' {
				// 	score += 1
				// }
			}

			// sud ouest
			if y - 3 >= 0 && x - 3 > 0 {
				if ws[x][y] == 'X' &&
				   ws[x - 1][y + 1] == 'M' &&
				   ws[x - 2][y + 2] == 'A' &&
				   ws[x - 3][y + 3] == 'S' {
					score += 1
				}
				// if ws[x][y] == 'S' &&
				//    ws[x - 1][y + 1] == 'A' &&
				//    ws[x - 2][y + 2] == 'M' &&
				//    ws[x - 3][y + 3] == 'X' {
				// 	score += 1
				// }
			}
		}
	}

	fmt.println(score)
	assert(score > 1524 && score < 2831)
}
