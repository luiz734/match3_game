extends Node

## Has the basic functions for a Match 3 Game.
## All function DON'T change any argument. Instead, they return a new value.
class_name Match3Core

## Maximum length for a match of type "N in a row or col". 
const MAX_N_LENGTH = 5
## Elements that cant be used anymore.
var removed_from_poll: Array[bool] = [] 


## --------------- auxiliar classes & enums ---------------
## The direction of a sequence.
enum Direction {
    HORIZONTAL,
    VERTICAL,
}
## Represents a sequence of the same elements in a line.
class SequenceData:
    ## Where it starts.
    var index: int
    ## The length.
    var length: int
    ## Horizontal or Vertical
    var direction: Direction
    
    func _init(index, length, direction):
        self.index = index
        self.length = length
        self.direction = direction

enum MatchType {
    NO_MATCH,
    MATCH_5,
    MATCH_T,
    MATCH_4,
    MATCH_3,
}
## Represents a Match
class MatchData:
    var type: MatchType
    var indexes: Array
    
    func _init(type: MatchType, indexes: Array):
        self.type = type
        self.indexes = indexes


## --------------- core functionality ---------------
func _init(grid_size: int) -> void:
    for i in range(grid_size * grid_size):
        removed_from_poll.push_back(false)

## Remove all elements in arr from the poll.
func remove_from_poll(arr: Array):
    for a in arr:
        removed_from_poll[a] = true
        Events.piece_removed_from_poll.emit(a)

## Finds a match of type N.
## A sequence of N elements in a line (row or col).
## The max size of match sequence is given by MAX_N_LENGTH.
## Returns an array with index of the elements in the match.
func find_match_N(n: int, matches: Array[Array], grid_size: int) -> Array:
    for m in matches:
        assert(typeof(m[0]) == TYPE_INT)
        if len(m) == n:
            return m
    return []

## Remove the duplicates of arr.
## Returns a new array without the duplicates.
func _remove_duplicates(arr: Array) -> Array:
    # Uses a dictionary as a set
    var set_arr = {}
    for x in arr:
        # Dumb value. Could be anything.
        set_arr[str(x)] = null
    var out_arr = []
    for x in set_arr.keys():
        out_arr.push_back(int(x))
    return out_arr

## Gets the 3 first elements of an array.
## Returns these elements as a new array.
func get_3_first_of_4(arr: Array) -> Array:
    assert(len(arr) == 4, "Expected an array of 4 as argument.")
    var x = arr.duplicate()
    x.pop_back()
    return x
## Gets the 3 last elements of an array.
## Returns these elements as a new array. 
func get_3_last_of_4(arr) -> Array:
    assert(len(arr) == 4, "Expected an array of 4 as argument.")
    var x = arr.duplicate()
    x.pop_front()
    return x
## Checks if 2 sequence intersects each other making a match T.
## Returns the elements that make the T match, or an empty array if any.
func find_T_intersection(match_center: Array, match_edges: Array) -> Array:
    assert(len(match_center) <= 4 and len(match_edges) <= 4, "Matches N=5 must be addressed first.")
        
    # Break ONE length 4 into TWO length 3. Solve it recursivelly.
    if len(match_center) == 4:
        var first_3 = get_3_first_of_4(match_center)
        var first_3_T = find_T_intersection(first_3, match_edges)
        if not first_3_T.is_empty(): return first_3_T
        var last_3 = get_3_last_of_4(match_center)
        var last_3_T = find_T_intersection(last_3, match_edges)
        return last_3_T
    # The same, but swap the checks.
    if len(match_edges) == 4:
        var first_3 = get_3_first_of_4(match_edges)
        var first_3_T = find_T_intersection(match_center, first_3)
        if not first_3_T.is_empty(): return first_3_T
        var last_3 = get_3_last_of_4(match_edges)
        var last_3_T = find_T_intersection(match_center, last_3)
        return last_3_T
    
    assert(len(match_center) == 3 and len(match_edges) == 3)
    # Base case. Easy to solve.
    var is_match_T = match_center[1] == match_edges[0] or match_center[1] == match_edges[2]
    if is_match_T:
        var combined = match_center.duplicate()
        combined.append_array(match_edges)
        return _remove_duplicates(combined)
    
    # If got here, there is no match-T.
    return []

## Check for match-T for all sequences.
## Return the match-T, if found one.
func find_match_T(sequence_h: Array, sequence_v: Array, grid_size) -> Array:
    for mh in sequence_h:
        for mv in sequence_v:
            # Try find matches with each of the sequence as "center" part of match-T.
            # A sequence A is "center" when the other sequence B cross sequence A in half.
            var match_h_center = find_T_intersection(mh, mv)
            if not match_h_center.is_empty(): return match_h_center
            
            var match_v_center = find_T_intersection(mv, mh)
            if not match_v_center.is_empty(): return match_v_center
    
    return []
    
## For a given line (row or col), find all sub-sequences of the same element.
## Elements are equal when cmp_func returns true.
## Returns [ [seq1_length, seq1_start_idx] , [seq2_length, seq2_start_idx], ... ].
## "end" is NOT INCLUSIVE.
func _get_subseqs_line(grid: Array, start: int, end: int, step: int, cmp_func: Callable) -> Array:
    var last_piece: Piece = grid[start]
    start = start + step
    var length := 1
    for i in range(start, end, step):
        var cur_piece: Piece = grid[i]
        if cmp_func.call(cur_piece, last_piece) and length < MAX_N_LENGTH:
            length += 1
        else:
            var subseq := _get_subseqs_line(grid, i, end, step, cmp_func)
            # Combine the current one with the next ones.
            subseq.push_back([length, start - step])
            return subseq
        last_piece = cur_piece
    # Base case. Will be recursivelly combined with the previous ones. 
    return [[length, start - step]]
      
## Converts each sequence from SequenceData to a raw array.
## Only elements in poll are added.
## Returns all of them in a new array (separated, NOT MERGED).
## Example: [ [1,2,3], [4, 5, 6] ].
func sequencedatas_in_poll_to_raw_arrays(sequences: Array[SequenceData], grid_size: int) -> Array[Array]:
    var seqs: Array[Array] = []
    for m in sequences:
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

## For all columns/rows, get the list of sequences.
## Returns all of them in a big array. 
func get_subseqs_all_lines(grid: Array, grid_size: int, cmp_func: Callable) -> Array[SequenceData]:
    var matches: Array[SequenceData] = []
    
    # horizontal
    for i in range(grid_size):
        var start = i * grid_size
        var end = (i + 1) * grid_size
        var step = 1
        var subseqs_line = _get_subseqs_line(grid, start, end, step, cmp_func)
        for subseq in subseqs_line:
            matches.push_back(
                SequenceData.new(
                    subseq[1],                  # index
                    subseq[0],                  # length
                    self.Direction.HORIZONTAL   # direction
                )
        )
    # vertical
    for i in range(grid_size):
        var start = i
        var end = (grid_size * grid_size) + i
        var step = grid_size
        var subseqs_line = _get_subseqs_line(grid, start, end, step, cmp_func)
        for subseq in subseqs_line:
            matches.push_back(
                SequenceData.new(
                    subseq[1],                  # index
                    subseq[0],                  # length
                    self.Direction.VERTICAL     # direction
                )
        )

    return matches

## Return an array of arrays, with which subarray being a candidate match.
## A candidate match is a match with length 3 or more.
func get_candidate_matches_as_arrays(pieces: Array, grid_size: int, cmp_func: Callable) -> Array[Array]:
    var subseqs = get_subseqs_all_lines(pieces, grid_size, cmp_func)
    # Longer sequences come first
    subseqs.sort_custom(func(x: SequenceData, y: SequenceData):
        return x.length > y.length
    )
    var raw_subseqs: Array[Array] = sequencedatas_in_poll_to_raw_arrays(subseqs, grid_size)
    # scorable = candidate to match in this context.
    var scorable_raw_subseqs: Array[Array] = raw_subseqs.filter(func(x):
        return len(x) >= 3    
    )
    return scorable_raw_subseqs

## Returns the next most valuable match, if any.
## The order of value is: MATCH_5, MATCH_T, MATCH_4, MATCH_3 (most valuable first)
func get_most_valuable_match(matches: Array, grid_size: int) -> MatchData:
    var match_5 = find_match_N(5, matches, grid_size)
    if not match_5.is_empty(): return MatchData.new(MatchType.MATCH_5, match_5)     

    # split 
    var h_matches = matches.filter(func(x): return abs(x[0] - x[1]) == 1)
    var v_matches = matches.filter(func(x): return abs(x[0] - x[1]) == grid_size)
    var match_T = find_match_T(h_matches, v_matches, grid_size)
    if not match_T.is_empty(): return MatchData.new(MatchType.MATCH_T, match_T)     

    var match_4 = find_match_N(4, matches, grid_size)
    if not match_4.is_empty(): return MatchData.new(MatchType.MATCH_4, match_4)     

    var match_3 = find_match_N(3, matches, grid_size)
    if not match_3.is_empty(): return MatchData.new(MatchType.MATCH_3, match_3)     
    
    return MatchData.new(MatchType.NO_MATCH, [])

## Returns a new array with all the non-null elements on bottom and all null on top
## This method DOESN'T change the source array
func get_notnull_first(grid: Array, grid_size: int, start: int, end: int, step: int) -> Array:
    var out_arr: Array = []
    var count = 0
    for i in range(start, end, step):
        if grid[i]:
            out_arr.push_back(grid[i])
            count += 1
    for i in range(len(out_arr), grid_size, 1):
        out_arr.push_back(null)
    # hack: change the logic so it's not necessary reverse
#    out_arr.reverse()
    assert(len(out_arr) == grid_size)
    return out_arr

func get_removed_from_poll_indexes(grid_size: int) -> Array:
    var arr = []
    for i in range(grid_size * grid_size):
        if removed_from_poll[i]:
            arr.push_back(i)
    return arr

func reset_removed_from_poll():
    for i in range(len(removed_from_poll)):
        removed_from_poll[i] = false
