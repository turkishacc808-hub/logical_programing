% knowledge_base.pl
% Экспертная система кардиологической диагностики
% Структура правил: diagnosis_rule(ID, Diagnosis, Confidence, Findings)
% Структура НЕ-факторов: exclusion/2 — взаимоисключающие диагнозы

:- module(knowledge_base, [
    finding/2,
    diagnosis_rule/4,
    exclusion/2,
    symptom_label/2,
    diagnosis_label/2,
    action/2
]).

%% ============================================================
%% Клинические признаки (симптомы)
%% finding(SymptomAtom, ClinicalSeverityWeight)
%% ============================================================

finding(chest_pain,        0.90).
finding(dyspnea,           0.80).
finding(tachycardia,       0.70).
finding(bradycardia,       0.65).
finding(peripheral_edema,  0.75).
finding(fatigue,           0.55).
finding(palpitations,      0.60).
finding(syncope,           0.80).
finding(elevated_bp,       0.70).
finding(low_bp,            0.75).
finding(cyanosis,          0.85).
finding(diaphoresis,       0.80).
finding(st_elevation,      0.95).
finding(irregular_rhythm,  0.75).
finding(friction_rub,      0.90).

%% ============================================================
%% Диагностические правила
%% diagnosis_rule(RuleID, Diagnosis, Confidence, RequiredFindings)
%%
%% Семантика: если все симптомы из RequiredFindings присутствуют
%% у пациента, правило активируется с весом Confidence.
%% Итоговая уверенность = 1 - prod(1 - wi) по активным правилам.
%% ============================================================

%% --- Ишемическая болезнь сердца (cad) ---
diagnosis_rule(cad_r1, cad, 0.85,
    [chest_pain, dyspnea, fatigue]).

diagnosis_rule(cad_r2, cad, 0.80,
    [chest_pain, elevated_bp, tachycardia]).

diagnosis_rule(cad_r3, cad, 0.70,
    [chest_pain, diaphoresis, dyspnea]).

diagnosis_rule(cad_r4, cad, 0.65,
    [fatigue, dyspnea, elevated_bp]).

%% --- Сердечная недостаточность (heart_failure) ---
diagnosis_rule(hf_r1, heart_failure, 0.88,
    [dyspnea, peripheral_edema, fatigue]).

diagnosis_rule(hf_r2, heart_failure, 0.82,
    [dyspnea, cyanosis, peripheral_edema]).

diagnosis_rule(hf_r3, heart_failure, 0.75,
    [tachycardia, peripheral_edema, fatigue]).

diagnosis_rule(hf_r4, heart_failure, 0.68,
    [dyspnea, low_bp, fatigue]).

%% --- Аритмия (arrhythmia) ---
diagnosis_rule(arr_r1, arrhythmia, 0.90,
    [palpitations, irregular_rhythm, syncope]).

diagnosis_rule(arr_r2, arrhythmia, 0.85,
    [tachycardia, palpitations, irregular_rhythm]).

diagnosis_rule(arr_r3, arrhythmia, 0.78,
    [bradycardia, syncope, fatigue]).

diagnosis_rule(arr_r4, arrhythmia, 0.65,
    [palpitations, dyspnea, irregular_rhythm]).

%% --- Гипертоническая болезнь (hypertension) ---
diagnosis_rule(htn_r1, hypertension, 0.87,
    [elevated_bp, chest_pain, fatigue]).

diagnosis_rule(htn_r2, hypertension, 0.80,
    [elevated_bp, tachycardia, palpitations]).

diagnosis_rule(htn_r3, hypertension, 0.75,
    [elevated_bp, dyspnea, fatigue]).

diagnosis_rule(htn_r4, hypertension, 0.60,
    [elevated_bp, peripheral_edema, fatigue]).

%% --- Инфаркт миокарда (myocardial_infarction) ---
diagnosis_rule(mi_r1, myocardial_infarction, 0.95,
    [chest_pain, st_elevation, diaphoresis]).

diagnosis_rule(mi_r2, myocardial_infarction, 0.92,
    [chest_pain, st_elevation, low_bp]).

diagnosis_rule(mi_r3, myocardial_infarction, 0.88,
    [chest_pain, diaphoresis, low_bp, cyanosis]).

diagnosis_rule(mi_r4, myocardial_infarction, 0.78,
    [chest_pain, dyspnea, st_elevation, tachycardia]).

%% --- Перикардит (pericarditis) ---
diagnosis_rule(peri_r1, pericarditis, 0.93,
    [chest_pain, friction_rub, dyspnea]).

diagnosis_rule(peri_r2, pericarditis, 0.87,
    [friction_rub, tachycardia, fatigue]).

diagnosis_rule(peri_r3, pericarditis, 0.80,
    [chest_pain, friction_rub, elevated_bp]).

diagnosis_rule(peri_r4, pericarditis, 0.72,
    [friction_rub, diaphoresis, fatigue]).

%% Итого: 22 правила (по 4 на каждый диагноз, кроме mi и peri — 4 каждый)

%% ============================================================
%% Взаимные исключения (НЕ-факторы / exclusion constraints)
%% exclusion(DiagA, DiagB): если DiagA подтверждён с высокой
%% уверенностью, DiagB исключается, и наоборот.
%%
%% Клиническое обоснование:
%%   - Инфаркт миокарда исключает ИБС (ИМ — острая фаза ИБС)
%%   - Перикардит исключает сердечную недостаточность (разные
%%     этиологии, несовместимые в типичной форме)
%% ============================================================

exclusion(myocardial_infarction, cad).
exclusion(cad, myocardial_infarction).
exclusion(pericarditis, heart_failure).
exclusion(heart_failure, pericarditis).

%% ============================================================
%% Русские наименования симптомов
%% symptom_label(Atom, RussianName)
%% ============================================================

symptom_label(chest_pain,        'боль в груди').
symptom_label(dyspnea,           'одышка').
symptom_label(tachycardia,       'тахикардия').
symptom_label(bradycardia,       'брадикардия').
symptom_label(peripheral_edema,  'периферические отёки').
symptom_label(fatigue,           'быстрая утомляемость').
symptom_label(palpitations,      'сердцебиение').
symptom_label(syncope,           'обморок / потеря сознания').
symptom_label(elevated_bp,       'повышенное артериальное давление').
symptom_label(low_bp,            'пониженное артериальное давление').
symptom_label(cyanosis,          'цианоз').
symptom_label(diaphoresis,       'холодный пот').
symptom_label(st_elevation,      'подъём сегмента ST на ЭКГ').
symptom_label(irregular_rhythm,  'нерегулярный сердечный ритм').
symptom_label(friction_rub,      'шум трения перикарда').

%% ============================================================
%% Русские наименования диагнозов
%% diagnosis_label(Atom, RussianName)
%% ============================================================

diagnosis_label(cad,                   'Ишемическая болезнь сердца').
diagnosis_label(heart_failure,         'Сердечная недостаточность').
diagnosis_label(arrhythmia,            'Аритмия').
diagnosis_label(hypertension,          'Гипертоническая болезнь').
diagnosis_label(myocardial_infarction, 'Инфаркт миокарда').
diagnosis_label(pericarditis,          'Перикардит').

%% ============================================================
%% Клинические рекомендации (действия)
%% action(Diagnosis, RecommendedAction)
%% ============================================================

action(cad,
    'Направить на коронарографию; назначить антиагреганты и статины; \c
     мониторинг АД и ЭКГ в динамике.').

action(heart_failure,
    'Госпитализация для декомпенсации; диуретики, ингибиторы АПФ; \c
     контроль водного баланса и ЭхоКГ.').

action(arrhythmia,
    'Суточное мониторирование ЭКГ (Холтер); антиаритмическая терапия \c
     по типу нарушения ритма; при синкопе — имплантация ЭКС.').

action(hypertension,
    'Гипотензивная терапия (блокаторы РААС, β-блокаторы); \c
     диета с ограничением натрия; контроль АД 2×/сутки.').

action(myocardial_infarction,
    'ЭКСТРЕННАЯ ГОСПИТАЛИЗАЦИЯ. ЧКВ или тромболизис в течение 90 мин; \c
     аспирин 300 мг немедленно; мониторинг тропонина.').

action(pericarditis,
    'НПВС (ибупрофен 600 мг 3×/сутки) + колхицин; \c
     эхокардиография для исключения тампонады; ограничение физических нагрузок.').
