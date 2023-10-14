extends Node

class_name Match3Core

enum Direction {
    HORIZONTAL,
    VERTICAL,
}

var removed_from_poll: Array[bool] = []

class MatchData:
    var index: int
    var length: int
    var direction: Direction
    
    func _init(index, length, direction):
        self.index = index
        self.length = length
        self.direction = direction


func _init(grid_size):
    for i in range(grid_size * grid_size):
        removed_from_poll.push_back(false)

func remove_from_poll(arr: Array):
    for a in arr:
        removed_from_poll[a] = true
        Events.piece_removed_from_poll.emit(a)


func find_match_N(n: int, matches: Array[Array], grid_size: int) -> Array:
    for m in matches:
        assert(typeof(m[0]) == TYPE_INT)
        if len(m) == n:
            return m
    return []

func remove_duplicates(arr) -> Array:
    var set_arr = {}
    for x in arr:
        set_arr[str(x)] = null
    var out_arr = []
    for x in set_arr.keys():
        out_arr.push_back(int(x))
    return out_arr

func get_3_first(arr) -> Array:
    var x = arr.duplicate()
    x.pop_back()
    return x
    
func get_3_last(arr) -> Array:
    var x = arr.duplicate()
    x.pop_front()
    return x

func find_T_intersection(match_center: Array, match_edges: Array) -> Array:
    if len(match_center) > 4 or len(match_edges) > 4: return []
    
    if len(match_center) == 4:
        var first_3 = get_3_first(match_center)
        var first_3_T = find_T_intersection(first_3, match_edges)
        if not first_3_T.is_empty(): return first_3_T
        var last_3 = get_3_last(match_center)
        var last_3_T = find_T_intersection(last_3, match_edges)
#        if not last_3_T.is_empty(): return last_3_T
        return last_3_T
        
    if len(match_edges) == 4:
        var first_3 = get_3_first(match_edges)
        var first_3_T = find_T_intersection(match_center, first_3)
        if not first_3_T.is_empty(): return first_3_T
        var last_3 = get_3_last(match_edges)
        var last_3_T = find_T_intersection(match_center, last_3)
#        if not last_3_T.is_empty(): return last_3_T
        return last_3_T
    
    
    assert(len(match_center) == 3 and len(match_edges) == 3 )
    
    var intersect = match_center[1] == match_edges[0] or match_center[1] == match_edges[2]
    if intersect:
        var combined = match_center.duplicate()
        combined.append_array(match_edges)
        return remove_duplicates(combined)
              
    return []

func find_match_T(matches_h: Array, matches_v: Array, grid_size):
    for mh in matches_h:
        for mv in matches_v:
            var match_h_center = find_T_intersection(mh, mv)
            if not match_h_center.is_empty(): return match_h_center
            
            var match_v_center = find_T_intersection(mv, mh)
            if not match_v_center.is_empty(): return match_v_center
    
    return []
    
    
    
    # Generate 2 sets (there is no set in godot, but dictionaries can behave like one)
    # set_matches: a set containing all elements of a list, that can be vertical or horizontal
    # set_mathces...: the same, bue the first and last elements are removed
    # EXPLANATION 
    # 1. if there is a T match, 2 lines intersect
    # 2. if 2 lines intersect, they MUST have 1 element in common
    # 3. because a T match can't interset in the edges of both list (woudn't be a T)
    #    we remove the edges from one of them.
    var set_matches = {}
    for x in matches_h:
        for i in range(0, len(x)):
            assert(len(x) <= 4, "this will break the logic")
            set_matches[str(x[i])] = x
            
    var set_matches_witout_edges = {}
    for x in matches_v:
        for i in range(0, len(x)):
            if i > 0 and i < len(x) - 1:
                assert(len(x) <= 4, "this will break the logic")
                set_matches_witout_edges[str(x[i])] = x
    
    # Merge elements that intersect in a big set: we need to know
    # what are these elements, so we can remove them, animate, etc.
    var elements_with_duplicates = []
    for key in set_matches.keys():
        if set_matches_witout_edges.has(key):
            # Can be length 4 or 3
            var longest_T_arm: Array = set_matches.get(key).duplicate()
            # ALWAYS will be length 2 or less (we remove the edges)
            var shortest_T_arm: Array = set_matches_witout_edges.get(key).duplicate()
#            assert(len(shortest_T_arm) <= 2, "should always be true.")
    
            # Remove extra tip from longest arm: not part of T match
            # For length 4, we need to find what tip is not part of the match
            # The step is calculated based on what is the first arg:
            # vertical matches or horizontal matches
            var step = abs(longest_T_arm[0] - longest_T_arm[1])
            assert(step == 1 or step == grid_size, "step must be 1 or grid_size") 
            
            var remove_start = shortest_T_arm.any(func(x):
                x == longest_T_arm[0] or x == longest_T_arm[0] + step
            ) and len(longest_T_arm) == 4
            
            if remove_start:
                longest_T_arm.pop_front()
            else:
                longest_T_arm.pop_back()
            
            elements_with_duplicates = shortest_T_arm
            elements_with_duplicates.append_array(longest_T_arm)
    
            # remove duplicates
            var set_without_duplicates = {}
            for e in elements_with_duplicates:
                set_without_duplicates[str(e)] = null
            
            var arr_without_duplicates = Array(set_without_duplicates.keys())
            return arr_without_duplicates.map(func(x): return int(x))
    
    return []
   

## For a given line (row or col), find the longest sub-sequence of the same element.
## Elements are equal when cmp_func returns true.
## Returns [length, start_idx].
## "end" is NOT INCLUSIVE.
func _get_max_subseq_line(grid: Array, start: int, end: int, step: int, cmp_func: Callable) -> Array:
    var last_piece: Piece = grid[start]
    start = start + step
    var count := 1
    for i in range(start, end, step):
        var cur_piece: Piece = grid[i]
        if cmp_func.call(cur_piece, last_piece):
            count += 1
        else:
            var subseq := _get_max_subseq_line(grid, i, end, step, cmp_func)
            if subseq[0] > count:
                return subseq
            else:
                return [count, start - step]
        last_piece = cur_piece
    
#    print("index", start - step, " length", count)
    return [count, start - step]
      
## Converts each match from MatchData to a raw array. Returns all of them combined.
func matchdata_to_raw_arrays(matches: Array[MatchData], grid_size: int) -> Array[Array]:
    var seqs: Array[Array] = []
    for m in matches:
        var s := []
        var start := m.index
        
        var end := m.index + m.length
        var step := 1
        if m.direction == Direction.VERTICAL:
            end = m.index + (m.length * grid_size)
            step = grid_size
            
        for i in range(start, end, step):
            if not removed_from_poll[i]:
                s.push_back(i)
        
        seqs.push_back(s)
            
    return seqs


## Get a list of max sequence of pieces that match for each row and column
func get_max_subseq_all_lines(grid: Array, grid_size: int, cmp_func: Callable) -> Array[MatchData]:
    var matches: Array[MatchData] = []
    
    # horizontal
    for i in range(grid_size):
        var start = i * grid_size
        var end = (i + 1) * grid_size
        var step = 1
        var max_subseq = _get_max_subseq_line(grid, start, end, step, cmp_func)
        matches.push_back(
            MatchData.new(
                max_subseq[1],              # index
                max_subseq[0],              # length
                self.Direction.HORIZONTAL   # direction
            )
        )
    # vertical
    for i in range(grid_size):
        var start = i
        var end = (grid_size * grid_size) + i
        var step = grid_size
        var max_subseq = _get_max_subseq_line(grid, start, end, step, cmp_func)
        matches.push_back(
            MatchData.new(
                max_subseq[1],              # index
                max_subseq[0],              # length
                self.Direction.VERTICAL     # direction
            )
        )

    return matches

## Return an array of arrays, with which subarray being a candidate match
## A candidate match is a match with length 3 or more
func get_candidate_matches_as_arrays(pieces: Array, grid_size: int, cmp_func: Callable) -> Array[Array]:
    var max_subseqs = get_max_subseq_all_lines(pieces, grid_size, cmp_func)
    # longer matches come first
    max_subseqs.sort_custom(func(x: MatchData, y: MatchData):
        return x.length > y.length
    )
    
    var raw_matches: Array[Array] = matchdata_to_raw_arrays(max_subseqs, grid_size)
    
    var scorable_raw_matches: Array[Array] = raw_matches.filter(func(x):
        return len(x) >= 3    
    )
    return scorable_raw_matches
    
