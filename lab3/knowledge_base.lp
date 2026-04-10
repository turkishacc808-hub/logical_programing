% knowledge_base.lp
% ASP-программа кардиологической диагностики (clingo / Answer Set Programming)
%
% Структура:
%   finding/1        — наблюдаемые клинические признаки пациента
%   fires/1          — правило активировано (все антецеденты выполнены)
%   diagnosis/1      — вынесенный диагноз
%   excluded/1       — диагноз исключён НЕ-фактором
%   support/2        — поддержка диагноза (количество активных правил)
%   best_diagnosis/1 — итоговый диагноз по #maximize
%
% Запуск: clingo knowledge_base.lp facts_patient.lp --models=0

% ============================================================
% Домен диагнозов
% ============================================================

possible_diagnosis(cad).
possible_diagnosis(heart_failure).
possible_diagnosis(arrhythmia).
possible_diagnosis(hypertension).
possible_diagnosis(myocardial_infarction).
possible_diagnosis(pericarditis).

% ============================================================
% Правила активации (fires/1)
% Правило срабатывает, если все его признаки присутствуют у пациента
% ============================================================

% --- ИБС ---
fires(cad_r1)  :- finding(chest_pain),  finding(dyspnea),      finding(fatigue).
fires(cad_r2)  :- finding(chest_pain),  finding(elevated_bp),  finding(tachycardia).
fires(cad_r3)  :- finding(chest_pain),  finding(diaphoresis),  finding(dyspnea).
fires(cad_r4)  :- finding(fatigue),     finding(dyspnea),      finding(elevated_bp).

% --- Сердечная недостаточность ---
fires(hf_r1)   :- finding(dyspnea),     finding(peripheral_edema), finding(fatigue).
fires(hf_r2)   :- finding(dyspnea),     finding(cyanosis),         finding(peripheral_edema).
fires(hf_r3)   :- finding(tachycardia), finding(peripheral_edema), finding(fatigue).
fires(hf_r4)   :- finding(dyspnea),     finding(low_bp),           finding(fatigue).

% --- Аритмия ---
fires(arr_r1)  :- finding(palpitations),    finding(irregular_rhythm), finding(syncope).
fires(arr_r2)  :- finding(tachycardia),     finding(palpitations),     finding(irregular_rhythm).
fires(arr_r3)  :- finding(bradycardia),     finding(syncope),          finding(fatigue).
fires(arr_r4)  :- finding(palpitations),    finding(dyspnea),          finding(irregular_rhythm).

% --- Гипертоническая болезнь ---
fires(htn_r1)  :- finding(elevated_bp),  finding(chest_pain),  finding(fatigue).
fires(htn_r2)  :- finding(elevated_bp),  finding(tachycardia), finding(palpitations).
fires(htn_r3)  :- finding(elevated_bp),  finding(dyspnea),     finding(fatigue).
fires(htn_r4)  :- finding(elevated_bp),  finding(peripheral_edema), finding(fatigue).

% --- Инфаркт миокарда ---
fires(mi_r1)   :- finding(chest_pain), finding(st_elevation),  finding(diaphoresis).
fires(mi_r2)   :- finding(chest_pain), finding(st_elevation),  finding(low_bp).
fires(mi_r3)   :- finding(chest_pain), finding(diaphoresis),   finding(low_bp),      finding(cyanosis).
fires(mi_r4)   :- finding(chest_pain), finding(dyspnea),       finding(st_elevation), finding(tachycardia).

% --- Перикардит ---
fires(peri_r1) :- finding(chest_pain),  finding(friction_rub), finding(dyspnea).
fires(peri_r2) :- finding(friction_rub), finding(tachycardia), finding(fatigue).
fires(peri_r3) :- finding(chest_pain),  finding(friction_rub), finding(elevated_bp).
fires(peri_r4) :- finding(friction_rub), finding(diaphoresis), finding(fatigue).

% ============================================================
% Соответствие правил и диагнозов
% ============================================================

rule_for(cad_r1,  cad).       rule_for(cad_r2,  cad).
rule_for(cad_r3,  cad).       rule_for(cad_r4,  cad).

rule_for(hf_r1,   heart_failure). rule_for(hf_r2,   heart_failure).
rule_for(hf_r3,   heart_failure). rule_for(hf_r4,   heart_failure).

rule_for(arr_r1,  arrhythmia). rule_for(arr_r2,  arrhythmia).
rule_for(arr_r3,  arrhythmia). rule_for(arr_r4,  arrhythmia).

rule_for(htn_r1,  hypertension). rule_for(htn_r2,  hypertension).
rule_for(htn_r3,  hypertension). rule_for(htn_r4,  hypertension).

rule_for(mi_r1,   myocardial_infarction). rule_for(mi_r2,   myocardial_infarction).
rule_for(mi_r3,   myocardial_infarction). rule_for(mi_r4,   myocardial_infarction).

rule_for(peri_r1, pericarditis). rule_for(peri_r2, pericarditis).
rule_for(peri_r3, pericarditis). rule_for(peri_r4, pericarditis).

% ============================================================
% Поддержка диагноза: число активных правил для данного диагноза
% ============================================================

support(D, N) :-
    possible_diagnosis(D),
    N = #count{ R : fires(R), rule_for(R, D) }.

% ============================================================
% Диагноз выносится, если хотя бы одно правило активировано
% ============================================================

diagnosis(D) :-
    possible_diagnosis(D),
    fires(R),
    rule_for(R, D).

% ============================================================
% НЕ-факторы: ограничения целостности (integrity constraints)
% Исключают несовместимые комбинации диагнозов
% ============================================================

% Инфаркт миокарда и ИБС не могут быть одновременно
% (ИМ — острая стадия, ИБС — хроническая)
excluded(cad)                   :- diagnosis(myocardial_infarction).
excluded(myocardial_infarction) :- diagnosis(cad),
                                   support(cad, Nc), support(myocardial_infarction, Nmi),
                                   Nc > Nmi.

% Перикардит и сердечная недостаточность взаимно исключаются
excluded(heart_failure)         :- diagnosis(pericarditis).
excluded(pericarditis)          :- diagnosis(heart_failure),
                                   support(heart_failure, Nhf), support(pericarditis, Np),
                                   Nhf > Np.

% Жёсткие ограничения целостности (integrity constraints)
% При одновременном подъёме ST исключаем перикардит в пользу ИМ
:- diagnosis(pericarditis), finding(st_elevation),
   support(myocardial_infarction, Nmi), Nmi > 0.

% ============================================================
% Активный набор диагнозов (без исключённых)
% ============================================================

active_diagnosis(D) :-
    diagnosis(D),
    not excluded(D).

% ============================================================
% Оптимизация: выбор диагноза с максимальной поддержкой
% (ASP-вариант ранжирования вместо вероятностного)
% ============================================================

#maximize { N,D : active_diagnosis(D), support(D, N) }.

% ============================================================
% Вывод результатов
% ============================================================

#show active_diagnosis/1.
#show support/2.
#show fires/1.
#show excluded/1.

% ============================================================
% Пример наблюдаемых фактов для запуска
% (раскомментировать или вынести в отдельный файл)
% ============================================================

% Случай 1: инфаркт миокарда
% finding(chest_pain).
% finding(st_elevation).
% finding(diaphoresis).
% finding(low_bp).

% Случай 2: перикардит
% finding(chest_pain).
% finding(friction_rub).
% finding(dyspnea).
% finding(fatigue).

% Случай 3: аритмия
% finding(palpitations).
% finding(irregular_rhythm).
% finding(syncope).

% Случай 4: конфликт ИМ/перикардит
% finding(chest_pain).
% finding(st_elevation).
% finding(friction_rub).
% finding(dyspnea).
