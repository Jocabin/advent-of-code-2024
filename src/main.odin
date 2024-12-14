package aoc

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strconv"

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

	day2()
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
