% inference.pl
% Модуль логического вывода для кардиологической экспертной системы
%
% Предикаты:
%   assess/3         — основной вывод: assess(Findings, Diagnosis, Confidence)
%   assess_all/2     — все диагнозы, отсортированные по убыванию уверенности
%   explain/3        — трасса объяснения вывода
%   validate_kb/0    — проверка полноты и согласованности базы знаний
%   case_assess/4    — оценка именованного тестового случая

:- use_module(knowledge_base).

%% ============================================================
%% assess(+Findings, ?Diagnosis, -Confidence)
%%
%% Основной предикат вывода. Вычисляет уверенность в диагнозе
%% по формуле: Conf = 1 - prod(1 - wi), где wi — веса активных
%% правил. Применяет НЕ-факторы (exclusion constraints).
%%
%% Findings — список атомов симптомов, наблюдаемых у пациента.
%% ============================================================

assess(Findings, Diagnosis, Confidence) :-
    % Собрать все диагнозы, для которых есть хоть одно активное правило
    diagnosis_label(Diagnosis, _),
    % Найти сработавшие правила
    fired_rules(Findings, Diagnosis, FiredRules),
    FiredRules \= [],
    % Вычислить итоговую уверенность
    compute_confidence(FiredRules, Confidence),
    Confidence > 0.0,
    % Проверить НЕ-факторы
    \+ is_excluded(Findings, Diagnosis).

%% ============================================================
%% fired_rules(+Findings, +Diagnosis, -FiredRules)
%%
%% Возвращает список пар rule(ID, Conf) активных правил для
%% данного диагноза при заданном наборе симптомов.
%% ============================================================

fired_rules(Findings, Diagnosis, FiredRules) :-
    findall(
        rule(RuleID, Conf),
        (
            diagnosis_rule(RuleID, Diagnosis, Conf, Required),
            all_present(Required, Findings)
        ),
        FiredRules
    ).

%% ============================================================
%% all_present(+Required, +Findings)
%%
%% Проверяет, что все элементы Required входят в Findings.
%% ============================================================

all_present([], _).
all_present([H|T], Findings) :-
    member(H, Findings),
    all_present(T, Findings).

%% ============================================================
%% compute_confidence(+FiredRules, -Confidence)
%%
%% Формула: Conf = 1 - ∏(1 - wi) по всем активным правилам.
%% Гарантирует результат в диапазоне [0.0, 1.0].
%% ============================================================

compute_confidence([], 0.0).
compute_confidence(FiredRules, Confidence) :-
    FiredRules \= [],
    maplist(extract_weight, FiredRules, Weights),
    foldl(multiply_complement, Weights, 1.0, Product),
    Confidence is 1.0 - Product.

extract_weight(rule(_, W), W).

multiply_complement(W, Acc, NewAcc) :-
    NewAcc is Acc * (1.0 - W).

%% ============================================================
%% is_excluded(+Findings, +Diagnosis)
%%
%% Проверяет, исключается ли диагноз НЕ-фактором на основе
%% правил exclusion/2: если конкурирующий диагноз подтверждён
%% с более высокой уверенностью, текущий исключается.
%% ============================================================

is_excluded(Findings, Diagnosis) :-
    exclusion(Diagnosis, Competitor),
    fired_rules(Findings, Competitor, CompRules),
    CompRules \= [],
    compute_confidence(CompRules, CompConf),
    fired_rules(Findings, Diagnosis, OwnRules),
    compute_confidence(OwnRules, OwnConf),
    CompConf > OwnConf.

%% ============================================================
%% assess_all(+Findings, -SortedResults)
%%
%% Возвращает список result(Diagnosis, Confidence) для всех
%% диагнозов с уверенностью > 0, отсортированных по убыванию.
%% ============================================================

assess_all(Findings, SortedResults) :-
    findall(
        result(Conf, Diagnosis),
        assess(Findings, Diagnosis, Conf),
        Pairs
    ),
    sort(0, @>=, Pairs, SortedPairs),
    maplist(flip_pair, SortedPairs, SortedResults).

flip_pair(result(Conf, Diag), result(Diag, Conf)).

%% ============================================================
%% explain(+Findings, +Diagnosis, -Trace)
%%
%% Генерирует трасску объяснения в виде списка:
%%   step(rule_fired, RuleID, Conf, MatchedFindings)
%%   step(excluded, Reason)
%%   step(conclusion, Diagnosis, FinalConf)
%% ============================================================

explain(Findings, Diagnosis, Trace) :-
    fired_rules(Findings, Diagnosis, FiredRules),
    maplist(explain_rule(Findings), FiredRules, RuleSteps),
    (
        is_excluded(Findings, Diagnosis)
    ->
        ExcStep = [step(excluded, Diagnosis, 'исключён НЕ-фактором')],
        FinalStep = []
    ;
        ExcStep = [],
        compute_confidence(FiredRules, Conf),
        FinalStep = [step(conclusion, Diagnosis, Conf)]
    ),
    append(RuleSteps, ExcStep, Temp),
    append(Temp, FinalStep, Trace).

explain_rule(Findings, rule(RuleID, Conf), Step) :-
    diagnosis_rule(RuleID, _Diag, Conf, Required),
    include(contains_in(Findings), Required, Matched),
    Step = step(rule_fired, RuleID, Conf, Matched).

contains_in(List, Elem) :- member(Elem, List).

%% ============================================================
%% validate_kb/0
%%
%% Проверяет базу знаний на полноту и согласованность:
%%   1. Каждый диагноз имеет хотя бы одно правило
%%   2. Каждый симптом в правилах объявлен как finding/2
%%   3. Все диагнозы в exclusion/2 корректны
%%   4. Веса уверенности в допустимом диапазоне [0.5, 1.0)
%% ============================================================

validate_kb :-
    writeln('=== Валидация базы знаний ==='),
    nl,
    validate_coverage,
    validate_symptoms,
    validate_exclusions,
    validate_weights,
    writeln('=== Валидация завершена без ошибок ===').

validate_coverage :-
    writeln('--- Покрытие диагнозов ---'),
    forall(
        diagnosis_label(D, Label),
        (
            findall(R, diagnosis_rule(R, D, _, _), Rules),
            length(Rules, N),
            (N > 0
             -> format('  [OK] ~w (~w): ~w правил~n', [D, Label, N])
             ;  format('  [!] ~w (~w): НЕТ правил!~n', [D, Label, N])
            )
        )
    ), nl.

validate_symptoms :-
    writeln('--- Символы в правилах vs finding/2 ---'),
    findall(S,
        (diagnosis_rule(_, _, _, Findings), member(S, Findings),
         \+ finding(S, _)),
        Unknown),
    sort(Unknown, UniqueUnknown),
    (UniqueUnknown = []
     -> writeln('  [OK] Все симптомы объявлены в finding/2')
     ;  format('  [!] Необъявленные симптомы: ~w~n', [UniqueUnknown])
    ), nl.

validate_exclusions :-
    writeln('--- Проверка exclusion/2 ---'),
    forall(
        exclusion(A, B),
        (
            (diagnosis_label(A, _) -> StatusA = ok ; StatusA = unknown),
            (diagnosis_label(B, _) -> StatusB = ok ; StatusB = unknown),
            format('  exclusion(~w, ~w): ~w/~w~n', [A, B, StatusA, StatusB])
        )
    ), nl.

validate_weights :-
    writeln('--- Веса уверенности правил ---'),
    findall(W-RuleID,
        (diagnosis_rule(RuleID, _, W, _), (W < 0.5 ; W >= 1.0)),
        BadWeights),
    (BadWeights = []
     -> writeln('  [OK] Все веса в диапазоне [0.5, 1.0)')
     ;  format('  [!] Некорректные веса: ~w~n', [BadWeights])
    ), nl.

%% ============================================================
%% case_assess(+CaseID, +Findings, +Expected, -Result)
%%
%% Оценивает именованный клинический случай.
%% Result = pass(Diagnosis, Conf) | fail(Got, Expected)
%% ============================================================

case_assess(CaseID, Findings, Expected, Result) :-
    assess_all(Findings, [result(TopDiag, TopConf)|_]),
    format('~nСлучай ~w:~n', [CaseID]),
    format('  Признаки: ~w~n', [Findings]),
    format('  Ожидаемый диагноз: ~w~n', [Expected]),
    format('  Полученный диагноз: ~w (уверенность: ~4f)~n', [TopDiag, TopConf]),
    (TopDiag == Expected
     -> Result = pass(TopDiag, TopConf),
        writeln('  Статус: PASS')
     ;  Result = fail(TopDiag, Expected),
        writeln('  Статус: FAIL')
    ).

case_assess(CaseID, Findings, Expected, fail(no_result, Expected)) :-
    \+ assess(Findings, _, _),
    format('~nСлучай ~w: нет активных правил для ~w~n', [CaseID, Findings]),
    format('  Ожидаемый: ~w, Статус: FAIL (no_result)~n', [Expected]).

%% ============================================================
%% print_results/1 — вывод результатов оценки
%% ============================================================

print_results([]).
print_results([result(Diag, Conf)|Rest]) :-
    diagnosis_label(Diag, Label),
    action(Diag, Act),
    format('  ~w (~w): уверенность = ~4f~n', [Diag, Label, Conf]),
    format('    Рекомендация: ~w~n', [Act]),
    print_results(Rest).

%% ============================================================
%% diagnose/1 — точка входа для интерактивного использования
%%
%% Пример:
%%   ?- diagnose([chest_pain, st_elevation, diaphoresis]).
%% ============================================================

diagnose(Findings) :-
    format('~n=== Кардиологическая диагностика ===~n'),
    format('Клинические признаки: ~w~n~n', [Findings]),
    assess_all(Findings, Results),
    (Results = []
     -> writeln('Ни одно правило не активировано.')
     ;  writeln('Результаты (по убыванию уверенности):'),
        print_results(Results)
    ).
