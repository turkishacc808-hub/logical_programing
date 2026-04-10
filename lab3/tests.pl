% tests.pl
% Тестовые случаи для кардиологической экспертной системы
%
% Структура: test_case(CaseID, Findings, ExpectedDiagnosis)
% Запуск: ?- run_tests.

:- use_module(knowledge_base).
:- use_module(inference).

%% ============================================================
%% Тестовые случаи (8 штук)
%% ============================================================

% Случай 1: Классический инфаркт миокарда
% Патогномоничные признаки: боль в груди + подъём ST + холодный пот
test_case(case_01,
    [chest_pain, st_elevation, diaphoresis, low_bp],
    myocardial_infarction).

% Случай 2: Острый перикардит
% Ключевой признак: шум трения перикарда + боль в груди
test_case(case_02,
    [chest_pain, friction_rub, dyspnea, fatigue],
    pericarditis).

% Случай 3: Декомпенсированная сердечная недостаточность
% Триада: одышка + периферические отёки + утомляемость
test_case(case_03,
    [dyspnea, peripheral_edema, fatigue, cyanosis],
    heart_failure).

% Случай 4: Аритмия с синкопальными эпизодами
% Нерегулярный ритм + сердцебиение + обмороки
test_case(case_04,
    [palpitations, irregular_rhythm, syncope, tachycardia],
    arrhythmia).

% Случай 5: Гипертоническая болезнь
% Стабильно повышенное АД + сопутствующие симптомы
test_case(case_05,
    [elevated_bp, chest_pain, fatigue, palpitations],
    hypertension).

% Случай 6: Ишемическая болезнь сердца (хроническая)
% Без подъёма ST, хроническая одышка и утомляемость
test_case(case_06,
    [chest_pain, dyspnea, fatigue, elevated_bp],
    cad).

% Случай 7 (конфликтный): ИМ vs ИБС — должен выиграть ИМ
% Наличие ST-подъёма и низкого АД указывает на острое состояние
test_case(case_07,
    [chest_pain, st_elevation, diaphoresis, tachycardia, dyspnea],
    myocardial_infarction).

% Случай 8 (конфликтный): Перикардит vs Сердечная недостаточность
% Шум трения перикарда — специфичный признак перикардита
test_case(case_08,
    [chest_pain, friction_rub, tachycardia, fatigue, dyspnea],
    pericarditis).

%% ============================================================
%% run_tests/0
%%
%% Запускает все тестовые случаи, выводит PASS/FAIL,
%% подсчитывает итоговую точность.
%% ============================================================

run_tests :-
    writeln(''),
    writeln('╔══════════════════════════════════════════════════════════╗'),
    writeln('║    Тестирование экспертной системы кардиодиагностики     ║'),
    writeln('╠══════════════════════════════════════════════════════════╣'),
    findall(CaseID-Findings-Expected,
            test_case(CaseID, Findings, Expected),
            Cases),
    run_cases(Cases, 0, 0, Passed, Total),
    nl,
    writeln('╠══════════════════════════════════════════════════════════╣'),
    format('║  Итого: ~w/~w тестов прошли~n', [Passed, Total]),
    Accuracy is Passed / Total * 100.0,
    format('║  Точность: ~1f%~n', [Accuracy]),
    writeln('╚══════════════════════════════════════════════════════════╝').

%% ============================================================
%% run_cases(+Cases, +AccPassed, +AccTotal, -TotalPassed, -Total)
%% ============================================================

run_cases([], Passed, Total, Passed, Total).
run_cases([CaseID-Findings-Expected|Rest], AccP, AccT, Passed, Total) :-
    run_single_case(CaseID, Findings, Expected, Status),
    NewAccT is AccT + 1,
    (Status == pass -> NewAccP is AccP + 1 ; NewAccP = AccP),
    run_cases(Rest, NewAccP, NewAccT, Passed, Total).

%% ============================================================
%% run_single_case(+CaseID, +Findings, +Expected, -Status)
%% ============================================================

run_single_case(CaseID, Findings, Expected, Status) :-
    writeln(''),
    format('┌─ ~w ──────────────────────────────────────────┐~n', [CaseID]),
    format('│  Симптомы: ~w~n', [Findings]),
    format('│  Ожидается: ~w~n', [Expected]),
    (
        assess_all(Findings, [result(TopDiag, TopConf)|_])
    ->
        format('│  Получено:  ~w (уверенность: ~4f)~n', [TopDiag, TopConf]),
        (TopDiag == Expected
         -> Status = pass,
            format('│  ✔ PASS~n', [])
         ;  Status = fail,
            format('│  ✘ FAIL (ожидалось ~w, получено ~w)~n', [Expected, TopDiag])
        )
    ;
        Status = fail,
        writeln('│  ✘ FAIL (нет активных правил)')
    ),
    format('└──────────────────────────────────────────────────────────┘~n', []).

%% ============================================================
%% run_test_with_explain/1
%%
%% Запускает один тест с полным объяснением трассы вывода.
%% Пример: ?- run_test_with_explain(case_01).
%% ============================================================

run_test_with_explain(CaseID) :-
    test_case(CaseID, Findings, Expected),
    format('~n=== Расширенный разбор случая ~w ===~n', [CaseID]),
    format('Симптомы: ~w~n', [Findings]),
    format('Ожидаемый диагноз: ~w~n~n', [Expected]),
    explain(Findings, Expected, Trace),
    format('Трасса вывода для ~w:~n', [Expected]),
    print_trace(Trace).

print_trace([]).
print_trace([step(rule_fired, RuleID, Conf, Matched)|Rest]) :-
    format('  → Правило ~w (вес ~4f): совпали признаки ~w~n',
           [RuleID, Conf, Matched]),
    print_trace(Rest).
print_trace([step(excluded, Diag, Reason)|Rest]) :-
    format('  ✗ Диагноз ~w исключён: ~w~n', [Diag, Reason]),
    print_trace(Rest).
print_trace([step(conclusion, Diag, Conf)|Rest]) :-
    format('  ✔ Вывод: ~w с уверенностью ~4f~n', [Diag, Conf]),
    print_trace(Rest).

%% ============================================================
%% show_all_diagnoses/1
%%
%% Показывает все активированные диагнозы для набора симптомов.
%% Пример: ?- show_all_diagnoses([chest_pain, friction_rub, st_elevation]).
%% ============================================================

show_all_diagnoses(Findings) :-
    format('~n=== Дифференциальный ряд для ~w ===~n~n', [Findings]),
    assess_all(Findings, Results),
    (Results = []
     -> writeln('Ни один диагноз не поддержан текущими данными.')
     ;  forall(
            member(result(Diag, Conf), Results),
            (
                diagnosis_label(Diag, Label),
                format('  ~w  (~w)  —  ~4f~n', [Diag, Label, Conf])
            )
        )
    ).
