:- encoding(utf8).
:- use_module(library(clpfd)).
:- use_module(library(lists)).

% -----------------------------
% Domain data
% -----------------------------

group(g101, 28).
group(g102, 30).
group(g103, 26).
group(g104, 24).
group(g105, 32).

subject(math).
subject(physics).
subject(prog).
subject(alg).
subject(db).
subject(networks).
subject(os).
subject(english).
subject(philosophy).
subject(economics).

teacher(ivanova).
teacher(petrov).
teacher(sidorov).
teacher(kuznetsova).
teacher(orlova).

day(mon).
day(tue).
day(wed).
day(thu).
day(fri).

day_index(mon, 1).
day_index(tue, 2).
day_index(wed, 3).
day_index(thu, 4).
day_index(fri, 5).

slot_time(1, '09:00').
slot_time(2, '10:40').
slot_time(3, '12:20').
slot_time(4, '14:00').
slot_time(5, '15:40').
slot_time(6, '17:20').

room(r101, 30, []).
room(r102, 40, []).
room(r103, 25, []).
room(r201, 35, [projector]).
room(r202, 40, [projector]).
room(r203, 35, [projector]).
room(lab1, 32, [pc, projector]).
room(lab2, 32, [pc]).
room(aud1, 100, [projector]).
room(aud2, 80, [projector]).

subject_req(math, []).
subject_req(physics, [projector]).
subject_req(prog, [pc]).
subject_req(alg, [pc]).
subject_req(db, [pc]).
subject_req(networks, [pc]).
subject_req(os, [pc]).
subject_req(english, []).
subject_req(philosophy, [projector]).
subject_req(economics, [projector]).

% -----------------------------
% Base schedule facts (one week)
% занятие(Группа, Предмет, Преподаватель, День, Пара, Аудитория)
% -----------------------------

занятие(g101, math, ivanova, mon, 1, r101).
занятие(g101, alg, ivanova, tue, 2, lab1).
занятие(g101, prog, sidorov, wed, 3, lab2).
занятие(g101, english, kuznetsova, thu, 2, r102).
занятие(g101, physics, petrov, fri, 1, r201).
занятие(g101, economics, orlova, fri, 4, r202).

занятие(g102, physics, petrov, mon, 2, r201).
занятие(g102, math, ivanova, tue, 1, r101).
занятие(g102, db, sidorov, wed, 2, lab1).
занятие(g102, english, kuznetsova, thu, 3, r102).
занятие(g102, philosophy, kuznetsova, thu, 5, r203).
занятие(g102, networks, petrov, fri, 2, lab2).

занятие(g103, prog, sidorov, mon, 3, lab1).
занятие(g103, physics, petrov, tue, 3, r202).
занятие(g103, math, ivanova, wed, 1, r101).
занятие(g103, os, sidorov, thu, 1, lab2).
занятие(g103, philosophy, kuznetsova, thu, 4, r203).
занятие(g103, english, kuznetsova, fri, 3, r102).

занятие(g104, english, kuznetsova, mon, 4, r102).
занятие(g104, prog, sidorov, tue, 4, lab2).
занятие(g104, math, ivanova, wed, 4, r101).
занятие(g104, physics, petrov, thu, 2, r201).
занятие(g104, db, sidorov, fri, 5, lab1).
занятие(g104, economics, orlova, fri, 6, r202).

занятие(g105, economics, orlova, mon, 5, aud1).
занятие(g105, philosophy, kuznetsova, tue, 5, r203).
занятие(g105, networks, petrov, wed, 5, lab1).
занятие(g105, prog, sidorov, thu, 5, lab2).
занятие(g105, math, ivanova, fri, 2, r102).
занятие(g105, english, kuznetsova, fri, 4, r102).

% -----------------------------
% Basic queries and helpers
% -----------------------------

when_group_subject(Group, Subject, Day, Slot, Room) :-
    занятие(Group, Subject, _, Day, Slot, Room).

когда_у_группы(Group, Subject, Day, Slot, Room) :-
    when_group_subject(Group, Subject, Day, Slot, Room).

free_room(Day, Slot, Room) :-
    room(Room, _, _),
    \+ занятие(_, _, _, Day, Slot, Room).

свободна_аудитория(Day, Slot, Room) :-
    free_room(Day, Slot, Room).

group_load(Group, Count) :-
    findall(1, занятие(Group, _, _, _, _, _), L),
    length(L, Count).

нагрузка_группы(Group, Count) :-
    group_load(Group, Count).

teacher_load(Teacher, Count) :-
    findall(1, занятие(_, _, Teacher, _, _, _), L),
    length(L, Count).

group_subjects(Group, Subjects) :-
    findall(Subject, занятие(Group, Subject, _, _, _, _), L),
    sort(L, Subjects).

teacher_groups(Teacher, Groups) :-
    findall(Group, занятие(Group, _, Teacher, _, _, _), L),
    sort(L, Groups).

группы_преподавателя(Teacher, Groups) :-
    teacher_groups(Teacher, Groups).

free_days_teacher(Teacher, Days) :-
    findall(Day, day(Day), AllDays),
    findall(Day, (member(Day, AllDays), \+ занятие(_, _, Teacher, Day, _, _)), Days).

свободные_дни_преподавателя(Teacher, Days) :-
    free_days_teacher(Teacher, Days).

pairs_per_day_group(Group, Day, Count) :-
    findall(1, занятие(Group, _, _, Day, _, _), L),
    length(L, Count).

teacher_schedule(Teacher, Lessons) :-
    findall(занятие(Group, Subject, Teacher, Day, Slot, Room),
            занятие(Group, Subject, Teacher, Day, Slot, Room),
            Lessons).

room_schedule(Room, Day, Slots) :-
    findall(Slot, занятие(_, _, _, Day, Slot, Room), L),
    sort(L, Slots).

% Windows in a group's schedule
windows_in_schedule(Group, Windows) :-
    findall(Day, day(Day), Days),
    findall(W, (member(Day, Days), windows_in_day(Group, Day, W)), Ws),
    sum_list(Ws, Windows).

окна_в_расписании(Group, Windows) :-
    windows_in_schedule(Group, Windows).

windows_in_day(Group, Day, Windows) :-
    findall(Slot, занятие(Group, _, _, Day, Slot, _), Slots),
    sort(Slots, Sorted),
    windows_from_slots(Sorted, Windows).

windows_from_slots([], 0).
windows_from_slots([_], 0).
windows_from_slots([S1, S2 | Rest], Windows) :-
    Gap is max(0, S2 - S1 - 1),
    windows_from_slots([S2 | Rest], TailWindows),
    Windows is Gap + TailWindows.

% -----------------------------
% Level 2 validation and metrics
% -----------------------------

нет_конфликтов_групп :-
    \+ (занятие(G, S1, T1, D, P, R1),
        занятие(G, S2, T2, D, P, R2),
        (S1, T1, R1) \= (S2, T2, R2)).

нет_конфликтов_преподавателей :-
    \+ (занятие(G1, S1, T, D, P, R1),
        занятие(G2, S2, T, D, P, R2),
        (G1, S1, R1) \= (G2, S2, R2)).

нет_конфликтов_аудиторий :-
    \+ (занятие(G1, S1, T1, D, P, R),
        занятие(G2, S2, T2, D, P, R),
        (G1, S1, T1) \= (G2, S2, T2)),
    \+ (занятие(G, S, _, _, _, R),
        \+ room_ok(G, S, R)).

room_ok(Group, Subject, Room) :-
    group(Group, Size),
    room(Room, Cap, Equip),
    Cap >= Size,
    subject_req(Subject, Need),
    equip_ok(Need, Equip).

equip_ok([], _).
equip_ok([H | T], Equip) :-
    member(H, Equip),
    equip_ok(T, Equip).

день_с_минимальной_нагрузкой(Group, Day) :-
    findall(D, day(D), Days),
    findall(Count-Day,
            (member(Day, Days), pairs_per_day_group(Group, Day, Count)),
            Counts),
    keysort(Counts, [ _-Day | _ ]).

подсчитать_окна(Group, Windows) :-
    окна_в_расписании(Group, Windows).

hours_per_pair(2).

перегруженные_преподаватели(Teachers) :-
    hours_per_pair(Hours),
    findall(Teacher,
            (teacher(Teacher),
             teacher_load(Teacher, Pairs),
             Pairs * Hours > 20),
            Teachers).

same_lesson(занятие(G, S, T, D, P, R), занятие(G, S, T, D, P, R)).

conflict_at(G, T, R, D, P, Ex1, Ex2) :-
    занятие(Gx, Sx, Tx, D, P, Rx),
    \+ same_lesson(занятие(Gx, Sx, Tx, D, P, Rx), Ex1),
    \+ same_lesson(занятие(Gx, Sx, Tx, D, P, Rx), Ex2),
    (Gx = G ; Tx = T ; Rx = R).

можно_переставить(L1, L2) :-
    L1 = занятие(G1, S1, T1, D1, P1, R1),
    L2 = занятие(G2, S2, T2, D2, P2, R2),
    L1 \= L2,
    room_ok(G1, S1, R2),
    room_ok(G2, S2, R1),
    \+ conflict_at(G1, T1, R2, D2, P2, L1, L2),
    \+ conflict_at(G2, T2, R1, D1, P1, L1, L2).

% -----------------------------
% Level 3: CLP(FD) generation
% -----------------------------

room_list([r101, r102, r103, r201, r202, r203, lab1, lab2, aud1, aud2]).

room_index(Room, Index) :-
    room_list(Rooms),
    nth1(Index, Rooms, Room).

day_list([mon, tue, wed, thu, fri]).

day_atom(Index, Atom) :-
    day_list(Days),
    nth1(Index, Days, Atom).

% Requirements: pairs per week and fixed teacher per group/subject
requirement(g101, math, 1).
requirement(g101, alg, 1).
requirement(g101, prog, 1).
requirement(g101, english, 1).
requirement(g101, physics, 1).
requirement(g101, economics, 1).

requirement(g102, physics, 1).
requirement(g102, math, 1).
requirement(g102, db, 1).
requirement(g102, english, 1).
requirement(g102, philosophy, 1).
requirement(g102, networks, 1).

requirement(g103, prog, 1).
requirement(g103, physics, 1).
requirement(g103, math, 1).
requirement(g103, os, 1).
requirement(g103, philosophy, 1).
requirement(g103, english, 1).

requirement(g104, english, 1).
requirement(g104, prog, 1).
requirement(g104, math, 1).
requirement(g104, physics, 1).
requirement(g104, db, 1).
requirement(g104, economics, 1).

requirement(g105, economics, 1).
requirement(g105, philosophy, 1).
requirement(g105, networks, 1).
requirement(g105, prog, 1).
requirement(g105, math, 1).
requirement(g105, english, 1).

teacher_for(g101, math, ivanova).
teacher_for(g101, alg, ivanova).
teacher_for(g101, prog, sidorov).
teacher_for(g101, english, kuznetsova).
teacher_for(g101, physics, petrov).
teacher_for(g101, economics, orlova).

teacher_for(g102, physics, petrov).
teacher_for(g102, math, ivanova).
teacher_for(g102, db, sidorov).
teacher_for(g102, english, kuznetsova).
teacher_for(g102, philosophy, kuznetsova).
teacher_for(g102, networks, petrov).

teacher_for(g103, prog, sidorov).
teacher_for(g103, physics, petrov).
teacher_for(g103, math, ivanova).
teacher_for(g103, os, sidorov).
teacher_for(g103, philosophy, kuznetsova).
teacher_for(g103, english, kuznetsova).

teacher_for(g104, english, kuznetsova).
teacher_for(g104, prog, sidorov).
teacher_for(g104, math, ivanova).
teacher_for(g104, physics, petrov).
teacher_for(g104, db, sidorov).
teacher_for(g104, economics, orlova).

teacher_for(g105, economics, orlova).
teacher_for(g105, philosophy, kuznetsova).
teacher_for(g105, networks, petrov).
teacher_for(g105, prog, sidorov).
teacher_for(g105, math, ivanova).
teacher_for(g105, english, kuznetsova).

% Entry point for generation
генерировать_расписание(Schedule) :-
    generate_schedule(Schedule).

generate_schedule(Schedule) :-
    lessons_from_requirements(Lessons),
    apply_constraints(Lessons, TotalWindows),
    collect_vars(Lessons, Vars0),
    Vars = [TotalWindows | Vars0],
    labeling([min(TotalWindows), ffc], Vars),
    materialize_schedule(Lessons, Schedule).

lessons_from_requirements(Lessons) :-
    findall(lesson(G, S, T, _Day, _Slot, _Room),
            (requirement(G, S, Count),
             teacher_for(G, S, T),
             between(1, Count, _)),
            Lessons),
    room_list(Rooms),
    length(Rooms, RoomCount),
    maplist(init_lesson_domains(RoomCount), Lessons).

init_lesson_domains(RoomCount, lesson(_, _, _, Day, Slot, Room)) :-
    Day in 1..5,
    Slot in 1..6,
    Room in 1..RoomCount.

apply_constraints(Lessons, TotalWindows) :-
    constrain_rooms(Lessons),
    no_conflicts_groups_clp(Lessons),
    no_conflicts_teachers_clp(Lessons),
    no_conflicts_rooms_clp(Lessons),
    balanced_group_loads(Lessons),
    total_windows(Lessons, TotalWindows).

constrain_rooms([]).
constrain_rooms([lesson(G, S, _, _, _, Room) | Rest]) :-
    suitable_room_indices(G, S, Allowed),
    list_to_fdset(Allowed, Set),
    Room in_set Set,
    constrain_rooms(Rest).

suitable_room_indices(Group, Subject, Indices) :-
    group(Group, Size),
    subject_req(Subject, Need),
    room_list(Rooms),
    findall(Index,
            (nth1(Index, Rooms, Room),
             room(Room, Cap, Equip),
             Cap >= Size,
             equip_ok(Need, Equip)),
            Indices),
    Indices \= [].

no_conflicts_groups_clp(Lessons) :-
    findall(G, group(G, _), Groups),
    maplist(no_conflicts_group(Lessons), Groups).

no_conflicts_group(Lessons, Group) :-
    collect_group_times(Lessons, Group, Times),
    all_distinct_if_needed(Times).

collect_group_times([], _, []).
collect_group_times([lesson(G, _, _, Day, Slot, _) | Rest], Group, Times) :-
    collect_group_times(Rest, Group, Tail),
    (G == Group ->
        Time #= Day * 10 + Slot,
        Times = [Time | Tail]
    ; Times = Tail
    ).

no_conflicts_teachers_clp(Lessons) :-
    findall(T, teacher(T), Teachers),
    maplist(no_conflicts_teacher(Lessons), Teachers).

no_conflicts_teacher(Lessons, Teacher) :-
    collect_teacher_times(Lessons, Teacher, Times),
    all_distinct_if_needed(Times).

collect_teacher_times([], _, []).
collect_teacher_times([lesson(_, _, T, Day, Slot, _) | Rest], Teacher, Times) :-
    collect_teacher_times(Rest, Teacher, Tail),
    (T == Teacher ->
        Time #= Day * 10 + Slot,
        Times = [Time | Tail]
    ; Times = Tail
    ).

no_conflicts_rooms_clp(Lessons) :-
    maplist(room_time_key, Lessons, Keys),
    all_distinct(Keys).

room_time_key(lesson(_, _, _, Day, Slot, Room), Key) :-
    Key #= Room * 100 + Day * 10 + Slot.

all_distinct_if_needed([]).
all_distinct_if_needed([_]).
all_distinct_if_needed(List) :-
    all_distinct(List).

balanced_group_loads(Lessons) :-
    findall(G, group(G, _), Groups),
    maplist(balanced_group_load(Lessons), Groups).

balanced_group_load(Lessons, Group) :-
    day_counts_for_group(Lessons, Group, Counts),
    maplist(limit_leq(3), Counts),
    bounded_diff(Counts, 2).

limit_leq(Limit, Value) :-
    Value #=< Limit.

bounded_diff([], _).
bounded_diff([_], _).
bounded_diff([X | Xs], Limit) :-
    maplist(diff_leq(X, Limit), Xs),
    bounded_diff(Xs, Limit).

diff_leq(X, Limit, Y) :-
    X - Y #=< Limit,
    Y - X #=< Limit.

day_counts_for_group(Lessons, Group, Counts) :-
    day_counts_for_group_(Lessons, Group, 1, Counts).

day_counts_for_group_(_, _, Day, []) :-
    Day > 5.
day_counts_for_group_(Lessons, Group, Day, [Count | Rest]) :-
    Day =< 5,
    day_count(Lessons, Group, Day, Count),
    Next is Day + 1,
    day_counts_for_group_(Lessons, Group, Next, Rest).

day_count(Lessons, Group, Day, Count) :-
    day_count_(Lessons, Group, Day, 0, Count).

day_count_([], _, _, Acc, Acc).
day_count_([lesson(G, _, _, DayVar, _, _) | Rest], Group, Day, Acc, Count) :-
    (G == Group ->
        B in 0..1,
        B #<==> (DayVar #= Day),
        Acc1 #= Acc + B
    ; Acc1 #= Acc
    ),
    day_count_(Rest, Group, Day, Acc1, Count).

total_windows(Lessons, Total) :-
    findall(G, group(G, _), Groups),
    total_windows_groups(Lessons, Groups, 0, Total).

total_windows_groups(_, [], Acc, Acc).
total_windows_groups(Lessons, [G | Rest], Acc, Total) :-
    total_windows_days(Lessons, G, 1, WGroup),
    Acc1 #= Acc + WGroup,
    total_windows_groups(Lessons, Rest, Acc1, Total).

total_windows_days(_, _, Day, 0) :-
    Day > 5.
total_windows_days(Lessons, Group, Day, TotalDay) :-
    Day =< 5,
    windows_for_group_day(Lessons, Group, Day, W),
    Next is Day + 1,
    total_windows_days(Lessons, Group, Next, Rest),
    TotalDay #= W + Rest.

windows_for_group_day(Lessons, Group, Day, Windows) :-
    occupancy_list(Lessons, Group, Day, 1, Occs),
    window_flags(Occs, Wins),
    sum(Wins, #=, Windows).

occupancy_list(_, _, _, Slot, []) :-
    Slot > 6.
occupancy_list(Lessons, Group, Day, Slot, [Occ | Rest]) :-
    Slot =< 6,
    occupancy_var(Lessons, Group, Day, Slot, Occ),
    Next is Slot + 1,
    occupancy_list(Lessons, Group, Day, Next, Rest).

occupancy_var(Lessons, Group, Day, Slot, Occ) :-
    count_group_day_slot(Lessons, Group, Day, Slot, Sum),
    Occ in 0..1,
    Sum #>= 1 #<==> Occ.

count_group_day_slot(Lessons, Group, Day, Slot, Count) :-
    count_group_day_slot_(Lessons, Group, Day, Slot, 0, Count).

count_group_day_slot_([], _, _, _, Acc, Acc).
count_group_day_slot_([lesson(G, _, _, DayVar, SlotVar, _) | Rest], Group, Day, Slot, Acc, Count) :-
    (G == Group ->
        B in 0..1,
        B #<==> (DayVar #= Day #/\ SlotVar #= Slot),
        Acc1 #= Acc + B
    ; Acc1 #= Acc
    ),
    count_group_day_slot_(Rest, Group, Day, Slot, Acc1, Count).

window_flags(Occs, Wins) :-
    findall(Win,
            (nth1(I, Occs, Occ),
             before_after(I, Occs, Before, After),
             Win #<==> (Occ #= 0 #/\ Before #= 1 #/\ After #= 1)),
            Wins).

before_after(I, Occs, Before, After) :-
    I1 is I - 1,
    length(Prefix, I1),
    append(Prefix, [_ | Suffix], Occs),
    bool_any(Prefix, Before),
    bool_any(Suffix, After).

bool_any([], 0).
bool_any(List, Any) :-
    Any in 0..1,
    sum(List, #=, Sum),
    Sum #>= 1 #<==> Any.

collect_vars(Lessons, Vars) :-
    term_variables(Lessons, Vars).

materialize_schedule(Lessons, Schedule) :-
    findall(занятие(G, S, T, DayAtom, Slot, RoomAtom),
            (member(lesson(G, S, T, Day, Slot, Room), Lessons),
             day_atom(Day, DayAtom),
             room_index(RoomAtom, Room)),
            Schedule).

экспортировать_csv(File, Schedule) :-
    setup_call_cleanup(
        open(File, write, Stream),
        write_csv(Stream, Schedule),
        close(Stream)
    ).

write_csv(Stream, Schedule) :-
    format(Stream, "group,subject,teacher,day,slot,room~n", []),
    forall(member(занятие(G, S, T, D, Slot, R), Schedule),
           format(Stream, "~w,~w,~w,~w,~w,~w~n", [G, S, T, D, Slot, R])).

экспортировать_html(File, Schedule) :-
    setup_call_cleanup(
        open(File, write, Stream),
        write_html(Stream, Schedule),
        close(Stream)
    ).

write_html(Stream, Schedule) :-
    format(Stream, "<!DOCTYPE html>~n<html><head><meta charset='UTF-8'>~n", []),
    format(Stream, "<title>Schedule</title></head><body>~n", []),
    format(Stream, "<table border='1' cellpadding='6' cellspacing='0'>~n", []),
    format(Stream, "<tr><th>Group</th><th>Subject</th><th>Teacher</th><th>Day</th><th>Slot</th><th>Room</th></tr>~n", []),
    forall(member(занятие(G, S, T, D, Slot, R), Schedule),
           format(Stream,
                  "<tr><td>~w</td><td>~w</td><td>~w</td><td>~w</td><td>~w</td><td>~w</td></tr>~n",
                  [G, S, T, D, Slot, R])),
    format(Stream, "</table>~n</body></html>~n", []).
