% family.pl
% Real genealogy knowledge base based on the British royal family.
% Main focus person: Elizabeth II and her ancestry/descendants.

% -----------------------------
% Base facts: gender
% -----------------------------

muzhchina(prince_albert).
muzhchina(edward_vii).
muzhchina(george_v).
muzhchina(george_vi).
muzhchina(prince_henry_gloucester).
muzhchina(prince_andrew_greece).
muzhchina(prince_philip).
muzhchina(charles_iii).
muzhchina(prince_andrew).
muzhchina(prince_edward).
muzhchina(prince_william).
muzhchina(prince_harry).
muzhchina(prince_george).
muzhchina(prince_louis).
muzhchina(edoardo_mapelli_mozzi).

zhenshchina(queen_victoria).
zhenshchina(princess_alice_uk).
zhenshchina(alexandra_of_denmark).
zhenshchina(mary_of_teck).
zhenshchina(elizabeth_bowes_lyon).
zhenshchina(elizabeth_ii).
zhenshchina(princess_margaret).
zhenshchina(victoria_hesse).
zhenshchina(princess_alice_battenberg).
zhenshchina(diana_spencer).
zhenshchina(sarah_ferguson).
zhenshchina(catherine_middleton).
zhenshchina(princess_anne).
zhenshchina(princess_beatrice).
zhenshchina(princess_eugenie).
zhenshchina(princess_charlotte).
zhenshchina(sienna_mapelli_mozzi).
zhenshchina(athena_mapelli_mozzi).

persona(X) :- muzhchina(X).
persona(X) :- zhenshchina(X).

% -----------------------------
% Base facts: parent-child
% -----------------------------

% Queen Victoria branch
roditel(queen_victoria, edward_vii).
roditel(prince_albert, edward_vii).
roditel(queen_victoria, princess_alice_uk).
roditel(prince_albert, princess_alice_uk).

roditel(edward_vii, george_v).
roditel(alexandra_of_denmark, george_v).

roditel(george_v, george_vi).
roditel(mary_of_teck, george_vi).
roditel(george_v, prince_henry_gloucester).
roditel(mary_of_teck, prince_henry_gloucester).

roditel(george_vi, elizabeth_ii).
roditel(elizabeth_bowes_lyon, elizabeth_ii).
roditel(george_vi, princess_margaret).
roditel(elizabeth_bowes_lyon, princess_margaret).

% Prince Philip branch (also descends from Queen Victoria)
roditel(princess_alice_uk, victoria_hesse).
roditel(victoria_hesse, princess_alice_battenberg).
roditel(princess_alice_battenberg, prince_philip).
roditel(prince_andrew_greece, prince_philip).

% Descendants of Elizabeth II
roditel(elizabeth_ii, charles_iii).
roditel(prince_philip, charles_iii).
roditel(elizabeth_ii, princess_anne).
roditel(prince_philip, princess_anne).
roditel(elizabeth_ii, prince_andrew).
roditel(prince_philip, prince_andrew).
roditel(elizabeth_ii, prince_edward).
roditel(prince_philip, prince_edward).

roditel(charles_iii, prince_william).
roditel(diana_spencer, prince_william).
roditel(charles_iii, prince_harry).
roditel(diana_spencer, prince_harry).

roditel(prince_william, prince_george).
roditel(catherine_middleton, prince_george).
roditel(prince_william, princess_charlotte).
roditel(catherine_middleton, princess_charlotte).
roditel(prince_william, prince_louis).
roditel(catherine_middleton, prince_louis).

roditel(prince_andrew, princess_beatrice).
roditel(sarah_ferguson, princess_beatrice).
roditel(prince_andrew, princess_eugenie).
roditel(sarah_ferguson, princess_eugenie).

roditel(princess_beatrice, sienna_mapelli_mozzi).
roditel(edoardo_mapelli_mozzi, sienna_mapelli_mozzi).
roditel(princess_beatrice, athena_mapelli_mozzi).
roditel(edoardo_mapelli_mozzi, athena_mapelli_mozzi).

% -----------------------------
% Extended attributes
% -----------------------------

% Birth dates
% data_rozhdeniya(Person, date(Year,Month,Day)).
data_rozhdeniya(queen_victoria, date(1819, 5, 24)).
data_rozhdeniya(prince_albert, date(1819, 8, 26)).
data_rozhdeniya(edward_vii, date(1841, 11, 9)).
data_rozhdeniya(princess_alice_uk, date(1843, 4, 25)).
data_rozhdeniya(alexandra_of_denmark, date(1844, 12, 1)).
data_rozhdeniya(victoria_hesse, date(1863, 4, 5)).
data_rozhdeniya(george_v, date(1865, 6, 3)).
data_rozhdeniya(mary_of_teck, date(1867, 5, 26)).
data_rozhdeniya(prince_andrew_greece, date(1882, 2, 2)).
data_rozhdeniya(princess_alice_battenberg, date(1885, 2, 25)).
data_rozhdeniya(george_vi, date(1895, 12, 14)).
data_rozhdeniya(prince_henry_gloucester, date(1900, 3, 31)).
data_rozhdeniya(elizabeth_bowes_lyon, date(1900, 8, 4)).
data_rozhdeniya(elizabeth_ii, date(1926, 4, 21)).
data_rozhdeniya(princess_margaret, date(1930, 8, 21)).
data_rozhdeniya(prince_philip, date(1921, 6, 10)).
data_rozhdeniya(charles_iii, date(1948, 11, 14)).
data_rozhdeniya(princess_anne, date(1950, 8, 15)).
data_rozhdeniya(sarah_ferguson, date(1959, 10, 15)).
data_rozhdeniya(prince_andrew, date(1960, 2, 19)).
data_rozhdeniya(diana_spencer, date(1961, 7, 1)).
data_rozhdeniya(prince_edward, date(1964, 3, 10)).
data_rozhdeniya(catherine_middleton, date(1982, 1, 9)).
data_rozhdeniya(prince_william, date(1982, 6, 21)).
data_rozhdeniya(prince_harry, date(1984, 9, 15)).
data_rozhdeniya(princess_beatrice, date(1988, 8, 8)).
data_rozhdeniya(princess_eugenie, date(1990, 3, 23)).
data_rozhdeniya(prince_george, date(2013, 7, 22)).
data_rozhdeniya(princess_charlotte, date(2015, 5, 2)).
data_rozhdeniya(prince_louis, date(2018, 4, 23)).
data_rozhdeniya(sienna_mapelli_mozzi, date(2021, 9, 18)).
data_rozhdeniya(athena_mapelli_mozzi, date(2025, 1, 22)).

% Death dates
data_smerti(queen_victoria, date(1901, 1, 22)).
data_smerti(prince_albert, date(1861, 12, 14)).
data_smerti(edward_vii, date(1910, 5, 6)).
data_smerti(princess_alice_uk, date(1878, 12, 14)).
data_smerti(alexandra_of_denmark, date(1925, 11, 20)).
data_smerti(george_v, date(1936, 1, 20)).
data_smerti(george_vi, date(1952, 2, 6)).
data_smerti(prince_andrew_greece, date(1944, 12, 3)).
data_smerti(princess_alice_battenberg, date(1969, 12, 5)).
data_smerti(victoria_hesse, date(1950, 9, 24)).
data_smerti(princess_margaret, date(2002, 2, 9)).
data_smerti(diana_spencer, date(1997, 8, 31)).
data_smerti(prince_philip, date(2021, 4, 9)).
data_smerti(elizabeth_ii, date(2022, 9, 8)).

% Birth places
mesto_rozhdeniya(queen_victoria, kensington_palace_london).
mesto_rozhdeniya(prince_albert, schloss_rosenau).
mesto_rozhdeniya(edward_vii, buckingham_palace_london).
mesto_rozhdeniya(princess_alice_uk, buckingham_palace_london).
mesto_rozhdeniya(alexandra_of_denmark, copenhagen).
mesto_rozhdeniya(george_v, marlborough_house_london).
mesto_rozhdeniya(george_vi, sandringham).
mesto_rozhdeniya(elizabeth_bowes_lyon, london).
mesto_rozhdeniya(princess_margaret, glamis_castle).
mesto_rozhdeniya(elizabeth_ii, mayfair_london).
mesto_rozhdeniya(prince_philip, corfu).
mesto_rozhdeniya(charles_iii, buckingham_palace_london).
mesto_rozhdeniya(princess_anne, clarence_house_london).
mesto_rozhdeniya(prince_andrew, buckingham_palace_london).
mesto_rozhdeniya(prince_edward, buckingham_palace_london).
mesto_rozhdeniya(prince_william, st_marys_hospital_london).
mesto_rozhdeniya(prince_harry, st_marys_hospital_london).
mesto_rozhdeniya(princess_beatrice, portland_hospital_london).
mesto_rozhdeniya(princess_eugenie, portland_hospital_london).
mesto_rozhdeniya(prince_george, st_marys_hospital_london).
mesto_rozhdeniya(princess_charlotte, st_marys_hospital_london).
mesto_rozhdeniya(prince_louis, st_marys_hospital_london).
mesto_rozhdeniya(sienna_mapelli_mozzi, chelsea_and_westminster_hospital).
mesto_rozhdeniya(athena_mapelli_mozzi, chelsea_and_westminster_hospital).

% Professions / roles
professiya(queen_victoria, monarch).
professiya(prince_albert, prince_consort).
professiya(edward_vii, monarch).
professiya(george_v, monarch).
professiya(george_vi, monarch).
professiya(elizabeth_bowes_lyon, queen_consort).
professiya(elizabeth_ii, monarch).
professiya(charles_iii, monarch).
professiya(prince_philip, prince_consort).
professiya(princess_anne, royal).
professiya(prince_andrew, royal).
professiya(prince_edward, royal).
professiya(prince_william, royal).
professiya(prince_harry, royal).
professiya(catherine_middleton, princess_of_wales).
professiya(princess_beatrice, royal).
professiya(princess_eugenie, royal).
professiya(edoardo_mapelli_mozzi, businessman).

% -----------------------------
% Level 1: simple derived relations
% -----------------------------

mat(X, Y) :- roditel(X, Y), zhenshchina(X).
otets(X, Y) :- roditel(X, Y), muzhchina(X).

dedushka(X, Y) :-
    muzhchina(X),
    roditel(X, Z),
    roditel(Z, Y).

babushka(X, Y) :-
    zhenshchina(X),
    roditel(X, Z),
    roditel(Z, Y).

sibling(X, Y) :-
    X \= Y,
    roditel(P, X),
    roditel(P, Y).

brat(X, Y) :- sibling(X, Y), muzhchina(X).
sestra(X, Y) :- sibling(X, Y), zhenshchina(X).

dyadya(X, Y) :-
    muzhchina(X),
    roditel(P, Y),
    sibling(X, P).

tyotya(X, Y) :-
    zhenshchina(X),
    roditel(P, Y),
    sibling(X, P).

% -----------------------------
% Level 1: recursive relations
% -----------------------------

predok(X, Y) :- roditel(X, Y).
predok(X, Y) :-
    roditel(X, Z),
    predok(Z, Y).

potomok(X, Y) :- predok(Y, X).

% -----------------------------
% Level 1: complex relations
% -----------------------------

dvoyurodny_brat(X, Y) :-
    muzhchina(X),
    X \= Y,
    roditel(PX, X),
    roditel(PY, Y),
    sibling(PX, PY).

predok_na_urovne(Predok, Chelovek, 1) :- roditel(Predok, Chelovek).
predok_na_urovne(Predok, Chelovek, Uroven) :-
    Uroven > 1,
    roditel(Rod, Chelovek),
    Uroven1 is Uroven - 1,
    predok_na_urovne(Predok, Rod, Uroven1).

est_obshchiy_predok_do(X, Y, MaxUroven) :-
    between(1, MaxUroven, U),
    predok_na_urovne(A, X, U),
    predok_na_urovne(A, Y, U),
    X \= Y.

troyurodnaya_sestra(X, Y) :-
    zhenshchina(X),
    X \= Y,
    predok_na_urovne(A, X, 4),
    predok_na_urovne(A, Y, 4),
    \+ est_obshchiy_predok_do(X, Y, 3).

% -----------------------------
% Level 2: generation, common ancestor, kinship distance
% -----------------------------

% Generation is the maximum known depth from any root ancestor.
pokolenie(P, N) :-
    setof(G, pokolenie_raw(P, G), Gs),
    last(Gs, N).

pokolenie_raw(P, 0) :- persona(P), \+ roditel(_, P).
pokolenie_raw(P, N) :-
    roditel(R, P),
    pokolenie_raw(R, N1),
    N is N1 + 1.

predok_s_glubinoy(Predok, Potomok, 1) :- roditel(Predok, Potomok).
predok_s_glubinoy(Predok, Potomok, N) :-
    roditel(R, Potomok),
    predok_s_glubinoy(Predok, R, N1),
    N is N1 + 1.

obshchiy_predok_ves(X, Y, SumDepth, A) :-
    predok_s_glubinoy(A, X, D1),
    predok_s_glubinoy(A, Y, D2),
    SumDepth is D1 + D2,
    X \= Y.

% Returns nearest common ancestors on backtracking.
obshchiy_predok(X, Y, A) :-
    setof(S-A1, obshchiy_predok_ves(X, Y, S, A1), [Min-_|_]),
    obshchiy_predok_ves(X, Y, Min, A).

sosed_po_grafu(X, Y) :- roditel(X, Y).
sosed_po_grafu(X, Y) :- roditel(Y, X).

put_mezhdu(X, Y, Path, Len) :-
    put_mezhdu_(X, Y, [X], RevPath, Len),
    reverse(RevPath, Path).

put_mezhdu_(Y, Y, Visited, Visited, 0).
put_mezhdu_(X, Y, Visited, Path, Len) :-
    sosed_po_grafu(X, Z),
    \+ member(Z, Visited),
    put_mezhdu_(Z, Y, [Z|Visited], Path, Len1),
    Len is Len1 + 1.

stepen_rodstva(X, Y, Distance) :-
    X \= Y,
    setof(L-P, put_mezhdu(X, Y, P, L), [Distance-_|_]).

% -----------------------------
% Level 2: validation
% -----------------------------

net_ciklov :-
    \+ (persona(P), predok(P, P)).

god_rozhdeniya(P, Y) :- data_rozhdeniya(P, date(Y, _, _)).

logichny_vozrasti :-
    \+ (
        roditel(Rod, Rebenok),
        god_rozhdeniya(Rod, YRod),
        god_rozhdeniya(Rebenok, YReb),
        YRod > YReb - 12
    ).

net_konfliktov_predkov :-
    \+ (persona(P), predok(P, P)).

% -----------------------------
% Level 3: relation text, DOT export, all paths
% -----------------------------

liniya_roditelya(Rod, Rebenok, 'po linii ottsa') :- otets(Rod, Rebenok), !.
liniya_roditelya(Rod, Rebenok, 'po linii materi') :- mat(Rod, Rebenok), !.
liniya_roditelya(_, _, 'po neizvestnoy linii').

dvoyurodny_dedushka(X, Y) :-
    muzhchina(X),
    roditel(P, Y),
    dvoyurodny_brat(X, P).

opisanie_rodstva(X, Y, Text) :-
    dvoyurodny_dedushka(X, Y),
    roditel(P, Y),
    dvoyurodny_brat(X, P),
    liniya_roditelya(P, Y, Liniya),
    format(atom(Text), '~w - dvoyurodny dedushka ~w ~w.', [X, Y, Liniya]),
    !.

opisanie_rodstva(X, Y, Text) :-
    otets(X, Y),
    format(atom(Text), '~w - otets ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    mat(X, Y),
    format(atom(Text), '~w - mat ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    dedushka(X, Y),
    format(atom(Text), '~w - dedushka ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    babushka(X, Y),
    format(atom(Text), '~w - babushka ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    dyadya(X, Y),
    format(atom(Text), '~w - dyadya ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    tyotya(X, Y),
    format(atom(Text), '~w - tyotya ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    dvoyurodny_brat(X, Y),
    format(atom(Text), '~w - dvoyurodny brat ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    troyurodnaya_sestra(X, Y),
    format(atom(Text), '~w - troyurodnaya sestra ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    predok(X, Y),
    format(atom(Text), '~w - predok ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, Text) :-
    potomok(X, Y),
    format(atom(Text), '~w - potomok ~w.', [X, Y]),
    !.

opisanie_rodstva(X, Y, 'rodstvo ne opredeleno') :-
    persona(X),
    persona(Y),
    X \= Y.

vse_puti_mezhdu(X, Y, Path) :-
    put_mezhdu(X, Y, Path, _).

node_style(P, 'shape=box,style=filled,fillcolor="#b3e5fc"') :- muzhchina(P), !.
node_style(P, 'shape=ellipse,style=filled,fillcolor="#f8bbd0"') :- zhenshchina(P), !.
node_style(_, 'shape=ellipse').

eksport_v_dot(FilePath) :-
    open(FilePath, write, S),
    write(S, 'digraph FamilyTree {\n'),
    write(S, '  rankdir=TB;\n'),
    write(S, '  node [fontname="Helvetica"];\n'),
    forall(
        persona(P),
        (
            node_style(P, Style),
            format(S, '  "~w" [label="~w",~w];\n', [P, P, Style])
        )
    ),
    forall(
        roditel(Rod, Rebenok),
        format(S, '  "~w" -> "~w";\n', [Rod, Rebenok])
    ),
    write(S, '}\n'),
    close(S).
