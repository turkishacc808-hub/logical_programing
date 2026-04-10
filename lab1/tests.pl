% tests.pl
% Run with:
%   swipl -q -s tests.pl

:- begin_tests(genealogy).

:- [family].

test(mat_true) :-
    once(mat(diana_spencer, prince_william)).

test(otets_true) :-
    once(otets(charles_iii, prince_william)).

test(dedushka_true) :-
    once(dedushka(prince_philip, prince_william)).

test(babushka_true) :-
    once(babushka(elizabeth_ii, prince_william)).

test(brat_true) :-
    once(brat(prince_harry, prince_william)).

test(sestra_true) :-
    once(sestra(princess_eugenie, princess_beatrice)).

test(dyadya_true) :-
    once(dyadya(prince_andrew, prince_william)).

test(tyotya_true) :-
    once(tyotya(princess_anne, prince_william)).

test(predok_recursive_true) :-
    once(predok(queen_victoria, prince_william)).

test(potomok_recursive_true) :-
    once(potomok(prince_william, queen_victoria)).

test(dvoyurodny_brat_true) :-
    once(dvoyurodny_brat(prince_william, princess_beatrice)).

test(troyurodnaya_sestra_true) :-
    once(troyurodnaya_sestra(elizabeth_ii, prince_philip)).

test(pokolenie_true) :-
    pokolenie(prince_george, 7).

test(obshchiy_predok_true) :-
    once((
        obshchiy_predok(prince_william, princess_beatrice, A),
        member(A, [elizabeth_ii, prince_philip])
    )).

test(stepen_rodstva_true) :-
    stepen_rodstva(queen_victoria, prince_william, 6).

test(net_ciklov_true) :-
    net_ciklov.

test(logichny_vozrasti_true) :-
    logichny_vozrasti.

test(net_konfliktov_predkov_true) :-
    net_konfliktov_predkov.

test(opisanie_rodstva_true) :-
    once((
        opisanie_rodstva(prince_andrew, prince_william, T),
        sub_atom(T, _, _, _, 'dyadya')
    )).

test(vse_puti_mezhdu_true) :-
    once((
        vse_puti_mezhdu(queen_victoria, prince_henry_gloucester, Path),
        Path = [queen_victoria, edward_vii, george_v, prince_henry_gloucester]
    )).

:- end_tests(genealogy).

:- initialization(main, main).

main(_Argv) :-
    ( run_tests -> halt(0) ; halt(1) ).

/*
Sample REPL queries with expected answers:

1) ?- mat(diana_spencer, prince_william).
   true.

2) ?- otets(charles_iii, prince_william).
   true.

3) ?- dedushka(prince_philip, prince_william).
   true.

4) ?- dyadya(prince_andrew, prince_william).
   true.

5) ?- predok(queen_victoria, prince_william).
   true.

6) ?- dvoyurodny_brat(prince_william, princess_beatrice).
   true.

7) ?- troyurodnaya_sestra(elizabeth_ii, prince_philip).
   true.

8) ?- obshchiy_predok(prince_william, princess_beatrice, A).
   A = elizabeth_ii ;
   A = prince_philip.

9) ?- stepen_rodstva(queen_victoria, prince_william, D).
   D = 6.

10) ?- opisanie_rodstva(prince_andrew, prince_william, T).
    T = 'prince_andrew - dyadya prince_william.'.
*/
